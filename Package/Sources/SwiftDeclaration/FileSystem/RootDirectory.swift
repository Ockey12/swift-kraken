//
//  RootDirectory.swift
//  Package
//
//  Created by Ockey on 2025/09/10.
//

import IndexStore

public struct RootDirectory: Equatable {
    public let directory: Directory
    let keyPathTable: KeyPathTable

    public func getSwiftDeclaration(withUSR usr: USR) -> SwiftDeclaration? {
        guard let keyPath = keyPathTable.abstractDeclarations[usr] else {
            return nil
        }

        return directory[keyPath: keyPath]?.swiftDeclaration
    }
}
