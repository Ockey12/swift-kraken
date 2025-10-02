//
//  IndexStoreClient.swift
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
public struct IndexStoreClient: Sendable {
    public var extract: @Sendable (_ indexStoreURL: URL, _ projectRootURL: URL) async throws -> IndexStoreResponse
}

extension IndexStoreClient: DependencyKey {
    public static let liveValue: Self = Self { indexStoreURL, projectRootURL in
        let indexStore = try IndexStore.open(store: indexStoreURL, lib: .open())
        var definitionUSRs: [Location: [USR]] = [:]
        var referenceOccurrences: [String: [Occurrence]] = [:]

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
                        definitionUSRs[location, default: []].append(USR(occurrenceUSR))
                        return true
                    }

                    if occurrence.roles.contains(.reference),
                       let referencedUSR = occurrence.symbol.usr {
                        referenceOccurrences[fullPath, default: []].append(Occurrence(usr: USR(referencedUSR), location: location))
                    }
                    return true
                } // try indexStore.forEachOccurrences(for: record)
                return true
            } // try indexStore.forEachRecordDependencies(for: unit)
            return true
        } // try indexStore.forEachUnits

        return IndexStoreResponse(
            definitionUSRs: definitionUSRs,
            referenceOccurrences: referenceOccurrences,
        )
    }
}

public extension DependencyValues {
    var indexStoreClient: IndexStoreClient {
        get { self[IndexStoreClient.self] }
        set { self[IndexStoreClient.self] = newValue }
    }
}
