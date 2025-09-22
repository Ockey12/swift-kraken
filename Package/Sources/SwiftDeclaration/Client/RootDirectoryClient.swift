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
        @Dependency(\.usrStoreClient) var usrStoreClient
        let usrStore = try await usrStoreClient.extract(
            indexStoreURL: indexStoreURL,
            projectRootURL: rootDirectoryURL,
        )

        let rootDirectory = try extractDirectory(from: rootDirectoryURL, usrStore: usrStore)

        return RootDirectory(
            directory: rootDirectory,
            keyPathTable: rootDirectory.generateKeyPath(fromRootDirectory: \.self),
            usrStore: usrStore,
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
    static func extractDirectory(from url: URL, usrStore: USRStore) throws -> Directory {
        let fileManager = FileManager.default
        let items = try fileManager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles],
        )

        var subDirectories: IdentifiedArrayOf<Directory> = []
        var files: IdentifiedArrayOf<File> = []

        for itemURL in items {
            var isDirectory: ObjCBool = false
            fileManager.fileExists(atPath: itemURL.path(), isDirectory: &isDirectory)

            if isDirectory.boolValue {
                let subDirectory = try extractDirectory(from: itemURL, usrStore: usrStore)
                subDirectories.append(subDirectory)
            } else if itemURL.pathExtension == "swift" {
                let file = try extractFile(from: itemURL, usrStore: usrStore)
                files.append(file)
            }
        }

        return Directory(
            fullPath: url.path(),
            subDirectories: subDirectories,
            files: files,
        )
    }

    static func extractFile(from url: URL, usrStore: USRStore) throws -> File {
        let sourceCode = try String(contentsOf: url, encoding: .utf8)
        let parsedCode = Parser.parse(source: sourceCode)
        let fullPath = url.path()
        let sourceLocationConverter = SourceLocationConverter(fileName: fullPath, tree: parsedCode)
        let visitor = AbstractDeclarationVisitor(
            in: fullPath,
            usrStore: usrStore,
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
