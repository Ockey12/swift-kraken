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

    public func getDeclaration(withUSR usr: USR) -> AbstractDeclaration? {
        guard let keyPath = keyPathTable.abstractDeclarations[usr] else {
            return nil
        }

        return directory[keyPath: keyPath]
    }
}

import Foundation
import Location

extension RootDirectory {
    static var dummy: Self {
        // referrer

        let referrerFilePath = "rootDirectory/referrerFile.swift"

        let referrerStructID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
        let referrerStructUSR = USR("referrerDeclaration")
        var referrerStruct = AbstractDeclaration(
            id: referrerStructID,
            name: "referrerDeclaration",
            kind: .struct,
            sourceLocationRange: Location(fullPath: referrerFilePath, line: 1, column: 1)
                ... Location(fullPath: referrerFilePath, line: 4, column: 1),
            definitionUSRs: [referrerStructUSR],
        )

        let referrerMethodID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let referrerMethodUSR = USR("referrerMethod")
        let referrerMethod = AbstractDeclaration(
            id: referrerMethodID,
            name: "referrerMethod",
            kind: .function,
            sourceLocationRange: Location(fullPath: referrerFilePath, line: 2, column: 1)
                ... Location(fullPath: referrerFilePath, line: 3, column: 1),
            definitionUSRs: [referrerMethodUSR],
        )
        referrerStruct.functions.append(referrerMethod)
        let referrerFile = File(
            fullPath: referrerFilePath,
            sourceCode: "",
            abstractDeclarations: [referrerStruct],
        )

        // referenced

        let referencedFilePath = "rootDirectory/referencedFile.swift"

        let referencedStructID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let referencedStructUSR = USR("referencedDeclaration")
        var referencedStruct = AbstractDeclaration(
            id: referencedStructID,
            name: "referencedDeclaration",
            kind: .struct,
            sourceLocationRange: Location(fullPath: referencedFilePath, line: 1, column: 1)
                ... Location(fullPath: referencedFilePath, line: 4, column: 1),
            definitionUSRs: [referencedStructUSR],
        )

        let referencedMethodID = UUID(uuidString: "00000000-0000-0000-0000-000000000003")!
        let referencedMethodUSR = USR("referencedMethod")
        let referencedMethod = AbstractDeclaration(
            id: referencedMethodID,
            name: "referencedMethod",
            kind: .function,
            sourceLocationRange: Location(fullPath: referencedFilePath, line: 2, column: 1)
                ... Location(fullPath: referencedFilePath, line: 3, column: 1),
            definitionUSRs: [referencedMethodUSR],
        )
        referencedStruct.functions.append(referencedMethod)

        let referencedFile = File(
            fullPath: referencedFilePath,
            sourceCode: "",
            abstractDeclarations: [referencedStruct],
        )

        // root directory

        let directory = Directory(
            fullPath: "",
            subDirectories: [],
            files: [
                referrerFile,
                referencedFile,
            ],
        )

        // KeyPath

        let rootDirectoryKeyPath: KeyPath<Directory?, Directory?> = \.?.self
        let referrerFileKeyPath: KeyPath<Directory?, File?> = \.?.files[id: referrerFilePath]
        let referencedFileKeyPath: KeyPath<Directory?, File?> = \.?.files[id: referencedFilePath]
        let referrerStructKeyPath: KeyPath<Directory?, AbstractDeclaration?> = referrerFileKeyPath.appending(path: \.?.abstractDeclarations[id: referrerStructID])
        let referrerMethodKeyPath: KeyPath<Directory?, AbstractDeclaration?> = referrerStructKeyPath.appending(path: \.?.functions[id: referrerMethodID])
        let referencedStructKeyPath: KeyPath<Directory?, AbstractDeclaration?> = referencedFileKeyPath.appending(path: \.?.abstractDeclarations[id: referencedStructID])
        let referencedMethodKeyPath: KeyPath<Directory?, AbstractDeclaration?> = referencedStructKeyPath.appending(path: \.?.functions[id: referencedMethodID])

        let keyPathTable = KeyPathTable(
            directories: ["": rootDirectoryKeyPath],
            files: [
                referrerFilePath: referrerFileKeyPath,
                referencedFilePath: referencedFileKeyPath,
            ],
            abstractDeclarations: [
                referrerStructUSR: referrerStructKeyPath,
                referrerMethodUSR: referrerMethodKeyPath,
                referencedStructUSR: referencedStructKeyPath,
                referencedMethodUSR: referencedMethodKeyPath,
            ],
        )

        return RootDirectory(directory: directory, keyPathTable: keyPathTable)
    }
}
