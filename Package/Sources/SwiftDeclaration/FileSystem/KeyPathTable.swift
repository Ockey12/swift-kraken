//
//  KeyPathTable.swift
//  Package
//
//  Created by Ockey on 2025/09/09.
//

import IndexStore

struct KeyPathTable: Equatable {
    var directories: [String: KeyPath<Directory?, Directory?>]
    var files: [String: KeyPath<Directory?, File?>]
    var abstractDeclarations: [USR: KeyPath<Directory?, AbstractDeclaration?>]

    mutating func merge(_ table: KeyPathTable) {
        directories.merge(table.directories, uniquingKeysWith: { current, _ in current })
        files.merge(table.files, uniquingKeysWith: { current, _ in current })
        abstractDeclarations.merge(table.abstractDeclarations, uniquingKeysWith: { current, _ in current })
    }
}
