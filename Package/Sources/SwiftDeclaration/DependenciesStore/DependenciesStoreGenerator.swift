//
//  DependenciesStoreGenerator.swift
//  Package
//
//  Created by Ockey on 2025/09/25.
//

import Algorithms
import Foundation
import IndexStore
import Location

enum DependenciesStoreGenerator {
    static func generateWithFile(_ file: File, indexStoreResponse: IndexStoreResponse) -> DependenciesStore {
        var store = DependenciesStore(referrerUSRs: [:], referencedUSRs: [:])
        guard let occurrences = indexStoreResponse.referenceOccurrences[file.fullPath] else {
            return store
        }

        for occurrence in occurrences {
            guard let topDeclaration = file.topDeclarations.first(where: {
                $0.sourceLocationRange.contains(occurrence.location)
            }) else {
                continue
            }

            store.merge(with: generateWithDeclaration(topDeclaration, occurrence: occurrence))
        }

        return store
    }

    static func generateWithDeclaration(_ declaration: AbstractDeclaration, occurrence: Occurrence) -> DependenciesStore {
        var store = DependenciesStore(referrerUSRs: [:], referencedUSRs: [:])
        guard let childDeclaration = declaration.sortedChildren.declaration(containing: occurrence.location) else {
            declaration.definitionUSRs.forEach { referrerUSR in
                store.referrerUSRs[occurrence.usr, default: []].append(referrerUSR)
                store.referencedUSRs[referrerUSR, default: []].append(occurrence.usr)
            }
            return store
        }

        return generateWithDeclaration(childDeclaration, occurrence: occurrence)
    }
}

private extension [AbstractDeclaration] {
    func declaration(containing location: Location) -> Element? {
        guard !isEmpty else {
            return nil
        }

        let index = partitioningIndex { $0.sourceLocationRange.contains(location) }

        return index == endIndex ? nil : self[index]
    }
}
