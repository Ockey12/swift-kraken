//
//  File.swift
//  Package
//
//  Created by Ockey on 2025/09/09.
//

import IdentifiedCollections

public struct File: Identifiable, Equatable, Hashable, Sendable {
    public var id: String {
        fullPath
    }

    public let fullPath: String

    public let sourceCode: String
    public internal(set) var topDeclarations: IdentifiedArrayOf<Declaration>

    func generateKeyPath(fromRootDirectory keyPath: KeyPath<Directory?, File?>) -> KeyPathTable {
        var table = KeyPathTable(directories: [:], files: [:], abstractDeclarations: [:])
        table.files[id] = keyPath

        for declaration in topDeclarations {
            table.merge(declaration.generateKeyPath(
                fromRootDirectory: keyPath.appending(path: \.?.topDeclarations[id: declaration.id]),
            ))
        }

        return table
    }
}
