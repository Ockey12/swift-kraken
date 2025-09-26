//
//  RootDirectoryClient.swift
//  Package
//
//  Created by Ockey on 2025/09/11.
//

import Dependencies
import DependenciesMacros
import Foundation
import IdentifiedCollections
import IndexStore
import SwiftParser
import SwiftSyntax

@DependencyClient
public struct RootDirectoryClient: Sendable {
    public var extract: @Sendable (_ rootDirectoryURL: URL, _ indexStoreURL: URL) async throws -> RootDirectory
}

extension RootDirectoryClient: DependencyKey {
    public static let liveValue: Self = Self { rootDirectoryURL, indexStoreURL in
        @Dependency(\.indexStoreClient) var indexStoreClient
        let indexStoreResponse = try await indexStoreClient.extract(
            indexStoreURL: indexStoreURL,
            projectRootURL: rootDirectoryURL,
        )

        let (rootDirectory, dependenciesStore) = try await extractDirectory(from: rootDirectoryURL, indexStoreResponse: indexStoreResponse)

        return RootDirectory(
            directory: rootDirectory,
            keyPathTable: rootDirectory.generateKeyPath(fromRootDirectory: \.self),
            dependenciesStore: dependenciesStore,
        )
    }
}

public extension DependencyValues {
    var rootDirectoryClient: RootDirectoryClient {
        get { self[RootDirectoryClient.self] }
        set { self[RootDirectoryClient.self] = newValue }
    }
}

private extension RootDirectoryClient {
    static func extractDirectory(from url: URL, indexStoreResponse: IndexStoreResponse) async throws -> (Directory, DependenciesStore) {
        enum TaskResult: Sendable {
            case directory(Directory, DependenciesStore)
            case file(File)
        }

        let fileManager = FileManager.default
        let items = try fileManager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles],
        )

        var subDirectories: IdentifiedArrayOf<Directory> = []
        var files: IdentifiedArrayOf<File> = []
        var dependenciesStore = DependenciesStore(referrerUSRs: [:], referencedUSRs: [:])

        try await withThrowingTaskGroup(of: TaskResult?.self) { group in
            for itemURL in items {
                let resourceValues = try itemURL.resourceValues(forKeys: [.isDirectoryKey])
                group.addTask {
                    if resourceValues.isDirectory == true {
                        let (subDirectory, store) = try await extractDirectory(from: itemURL, indexStoreResponse: indexStoreResponse)
                        return TaskResult.directory(subDirectory, store)
                    } else if itemURL.pathExtension == "swift" {
                        let file = try extractFile(from: itemURL, indexStoreResponse: indexStoreResponse)
                        return TaskResult.file(file)
                    }
                    return nil
                }
            }

            for try await result in group {
                guard let result else {
                    continue
                }

                switch result {
                case let .directory(subDirectory, store):
                    subDirectories.append(subDirectory)
                    dependenciesStore.merge(with: store)

                case let .file(file):
                    files.append(file)
                    dependenciesStore.merge(with: DependenciesStoreGenerator.generateWithFile(file, indexStoreResponse: indexStoreResponse))
                }
            }
        }

        return (Directory(fullPath: url.path(), subDirectories: subDirectories, files: files), dependenciesStore)
    }

    static func extractFile(from url: URL, indexStoreResponse: IndexStoreResponse) throws -> File {
        let sourceCode = try String(contentsOf: url, encoding: .utf8)
        let parsedCode = Parser.parse(source: sourceCode)
        let fullPath = url.path()
        let sourceLocationConverter = SourceLocationConverter(fileName: fullPath, tree: parsedCode)
        let visitor = AbstractDeclarationVisitor(
            in: fullPath,
            indexStoreResponse: indexStoreResponse,
            sourceLocationConverter: sourceLocationConverter,
        )

        visitor.walk(parsedCode)

        return File(
            fullPath: fullPath,
            sourceCode: sourceCode,
            abstractDeclarations: visitor.result,
        )
    }
}
