//
//  Directory.swift
//  Package
//
//  Created by Ockey on 2025/09/09.
//

import IdentifiedCollections

public struct Directory: Identifiable, Equatable, Hashable, Sendable {
    public var id: String {
        fullPath
    }

    public let fullPath: String

    public var subDirectories: IdentifiedArrayOf<Directory>
    public var files: IdentifiedArrayOf<File>

    public init(
        fullPath: String,
        subDirectories: IdentifiedArrayOf<Directory>,
        files: IdentifiedArrayOf<File>,
    ) {
        self.fullPath = fullPath
        self.subDirectories = subDirectories
        self.files = files
    }

    func generateKeyPath(fromRootDirectory keyPath: KeyPath<Directory?, Directory?>) -> KeyPathTable {
        var table = KeyPathTable(directories: [:], files: [:], abstractDeclarations: [:])
        table.directories[id] = keyPath

        for subDirectory in subDirectories {
            table.merge(subDirectory.generateKeyPath(
                fromRootDirectory: keyPath.appending(path: \.?.subDirectories[id: subDirectory.id]),
            ))
        }

        for file in files {
            table.merge(file.generateKeyPath(
                fromRootDirectory: keyPath.appending(path: \.?.files[id: file.id]),
            ))
        }

        return table
    }
}
