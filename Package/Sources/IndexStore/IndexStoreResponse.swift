//
//  IndexStoreResponse.swift
//  Package
//
//  Created by Ockey on 2025/09/08.
//

import Location

public struct IndexStoreResponse: Equatable, Sendable {
    public let definitionUSRs: [Location: [USR]]
    public let referenceOccurrences: [String: [Occurrence]]

    public init(
        definitionUSRs: [Location: [USR]],
        referenceOccurrences: [String: [Occurrence]],
    ) {
        self.definitionUSRs = definitionUSRs
        self.referenceOccurrences = referenceOccurrences
    }
}
