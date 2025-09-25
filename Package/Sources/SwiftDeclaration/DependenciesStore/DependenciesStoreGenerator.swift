//
//  DependenciesStoreGenerator.swift
//  Package
//
//  Created by Ockey on 2025/09/25.
//

import IndexStore

enum DependenciesStoreGenerator {
    static func generateWithFile(_ file: File, indexStoreResponse: IndexStoreResponse) -> DependenciesStore {
        var store = DependenciesStore(referrerUSRs: [:], referencedUSRs: [:])
        guard let occurrences = indexStoreResponse.referenceOccurrences[file.fullPath] else {
            return store
        }

        for occurrence in occurrences {
            guard let topDeclaration = file.abstractDeclarations.first(where: {
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
        guard let childDeclaration = declaration.childDeclarations.first(where: {
            $0.sourceLocationRange.contains(occurrence.location)
        }) else {
            declaration.definitionUSRs.forEach { referrerUSR in
                store.referrerUSRs[occurrence.usr, default: []].append(referrerUSR)
                store.referencedUSRs[referrerUSR, default: []].append(occurrence.usr)
            }
            return store
        }

        return generateWithDeclaration(childDeclaration, occurrence: occurrence)
    }
}
