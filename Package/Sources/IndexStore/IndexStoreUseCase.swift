//
//  IndexStoreUseCase.swift
//  Package
//
//  Created by Ockey on 2025/09/08.
//

import Foundation

public struct IndexStoreUseCase {
    public typealias Response = USRStore

    private let repository: IndexStoreRepository

    public init(repository: IndexStoreRepository) {
        self.repository = repository
    }

    public func extractUSR(indexStoreURL: URL, projectRootURL: URL) async throws -> Response {
        try await repository.extractUSR(indexStoreURL: indexStoreURL, projectRootURL: projectRootURL)
    }
}
