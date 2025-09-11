//
//  USRStoreClient.swift
//  Package
//
//  Created by Ockey on 2025/09/11.
//

import Dependencies
import DependenciesMacros
import Foundation
import Location
import SwiftIndexStore

@DependencyClient
public struct USRStoreClient: Sendable {
    public var extract: @Sendable (_ indexStoreURL: URL, _ projectRootURL: URL) async throws -> USRStore
}

extension USRStoreClient: DependencyKey {
    public static let liveValue: Self = Self { indexStoreURL, projectRootURL in
        let indexStore = try IndexStore.open(store: indexStoreURL, lib: .open())
        var definitionUSRs: [Location: Set<USR>] = [:]
        var referrerUSRs: [USR: Set<Occurrence>] = [:]
        var referencedUSRs: [USR: Set<Occurrence>] = [:]

        try indexStore.forEachUnits { unit in
            try indexStore.forEachRecordDependencies(for: unit) { dependency in
                guard case let .record(record) = dependency,
                      let recordPath = record.filePath,
                      recordPath.starts(with: projectRootURL.path()) else {
                    return true
                }

                try indexStore.forEachOccurrences(for: record) { occurrence in
                    guard let occurrenceUSR = occurrence.symbol.usr,
                          let fullPath = occurrence.location.path else {
                        return true
                    }
                    let location = Location(
                        fullPath: fullPath,
                        line: Int(occurrence.location.line),
                        column: Int(occurrence.location.column),
                    )

                    if occurrence.roles.contains(.definition) {
                        definitionUSRs[location, default: []].insert(USR(occurrenceUSR))
                        return true
                    }

                    if occurrence.roles.contains(.reference) {
                        indexStore.forEachRelations(for: occurrence) { relation in
                            guard let referrerUSR = relation.symbol.usr else {
                                return true
                            }
                            referrerUSRs[USR(occurrenceUSR), default: []].insert(Occurrence(usr: USR(referrerUSR), location: location))
                            referencedUSRs[USR(referrerUSR), default: []].insert(Occurrence(usr: USR(occurrenceUSR), location: location))
                            return true
                        }
                    }
                    return true
                } // try indexStore.forEachOccurrences(for: record)
                return true
            } // try indexStore.forEachRecordDependencies(for: unit)
            return true
        } // try indexStore.forEachUnits

        return USRStore(
            definitionUSRs: definitionUSRs,
            referrerUSRs: referrerUSRs,
            referencedUSRs: referencedUSRs,
        )
    }
}

extension DependencyValues {
    public var usrStoreClient: USRStoreClient {
        get { self[USRStoreClient.self] }
        set { self[USRStoreClient.self] = newValue }
    }
}
