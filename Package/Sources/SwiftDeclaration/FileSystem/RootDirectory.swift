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
    let usrStore: USRStore

    public func getDeclaration(withUSR usr: USR) -> AbstractDeclaration? {
        guard let keyPath = keyPathTable.abstractDeclarations[usr] else {
            return nil
        }

        return directory[keyPath: keyPath]
    }

    public func getReferrers(referencedUSR: USR) -> [AbstractDeclaration] {
        guard let occurrences = usrStore.referrerUSRs[referencedUSR] else {
            return []
        }

        var referrerDeclarations: [AbstractDeclaration] = []

        for occurrence in occurrences {
            guard let referrer = getDeclaration(withUSR: occurrence.usr) else {
                continue
            }
            referrerDeclarations.append(referrer)
        }

        return referrerDeclarations
    }

    public func getReferenced(referrerUSR: USR) -> [AbstractDeclaration] {
        guard let occurrences = usrStore.referencedUSRs[referrerUSR] else {
            return []
        }

        var referencedDeclaraions: [AbstractDeclaration] = []

        for occurrence in occurrences {
            guard let referenced = getDeclaration(withUSR: occurrence.usr) else {
                continue
            }
            referencedDeclaraions.append(referenced)
        }
        return referencedDeclaraions
    }
}

import Foundation
import Location

public extension RootDirectory {
    static var dummy: Self {
        // referrer method

        let referrerFilePath = "rootDirectory/referrerFile.swift"

        let referrerStructID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
        let referrerStructUSR = USR("referrerDeclaration")
        let referrerStructLocationRange = Location(fullPath: referrerFilePath, line: 1, column: 1)
            ... Location(fullPath: referrerFilePath, line: 4, column: 1)
        var referrerStruct = AbstractDeclaration(
            id: referrerStructID,
            hierarchicalNames: ["referrerDeclaration"],
            kind: .struct,
            sourceLocationRange: referrerStructLocationRange,
            definitionUSRs: [referrerStructUSR],
        )

        let referrerMethodID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let referrerMethodUSR = USR("referrerMethod")
        let referrerMethodLocationRange = Location(fullPath: referrerFilePath, line: 2, column: 1)
            ... Location(fullPath: referrerFilePath, line: 3, column: 1)
        let referrerMethod = AbstractDeclaration(
            id: referrerMethodID,
            hierarchicalNames: ["referrerDeclaration", "referrerMethod"],
            kind: .function,
            sourceLocationRange: referrerMethodLocationRange,
            definitionUSRs: [referrerMethodUSR],
        )
        referrerStruct.functions.append(referrerMethod)
        let referrerFile = File(
            fullPath: referrerFilePath,
            sourceCode: "",
            abstractDeclarations: [referrerStruct],
        )

        // referenced method

        let referencedFilePath = "rootDirectory/referencedFile.swift"

        let referencedStructID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let referencedStructUSR = USR("referencedDeclaration")
        let referencedStructLocationRange = Location(fullPath: referencedFilePath, line: 1, column: 1)
            ... Location(fullPath: referencedFilePath, line: 4, column: 1)
        var referencedStruct = AbstractDeclaration(
            id: referencedStructID,
            hierarchicalNames: ["referencedDeclaration"],
            kind: .struct,
            sourceLocationRange: referencedStructLocationRange,
            definitionUSRs: [referencedStructUSR],
        )

        let referencedMethodID = UUID(uuidString: "00000000-0000-0000-0000-000000000003")!
        let referencedMethodUSR = USR("referencedMethod")
        let referencedMethodLocationRange = Location(fullPath: referencedFilePath, line: 2, column: 1)
            ... Location(fullPath: referencedFilePath, line: 3, column: 1)
        let referencedMethod = AbstractDeclaration(
            id: referencedMethodID,
            hierarchicalNames: ["referencedDeclaration", "referencedMethod"],
            kind: .function,
            sourceLocationRange: referencedMethodLocationRange,
            definitionUSRs: [referencedMethodUSR],
        )
        referencedStruct.functions.append(referencedMethod)

        let referencedFile = File(
            fullPath: referencedFilePath,
            sourceCode: "",
            abstractDeclarations: [referencedStruct],
        )

        // referenced type
        let referencedTypeFilePath = "rootDirectory/referencedType.swift"

        let referencedTypeID = UUID(uuidString: "00000000-0000-0000-0000-000000000004")!
        let referencedTypeUSR = USR("referencedType")
        let referencedTypeLocationRange = Location(fullPath: referencedTypeFilePath, line: 1, column: 1)
            ... Location(fullPath: referencedTypeFilePath, line: 4, column: 1)
        var referencedType = AbstractDeclaration(
            id: referencedTypeID,
            hierarchicalNames: ["referencedType"],
            kind: .struct,
            sourceLocationRange: referencedTypeLocationRange,
            definitionUSRs: [referencedTypeUSR],
        )

        let notUsedMethodID = UUID(uuidString: "00000000-0000-0000-0000-000000000005")!
        let notUsedMethodUSR = USR("notUsedMethod")
        let notUsedMethodLocationRange = Location(fullPath: referencedTypeFilePath, line: 2, column: 1)
            ... Location(fullPath: referencedTypeFilePath, line: 3, column: 1)
        let notUsedMethod = AbstractDeclaration(
            id: notUsedMethodID,
            hierarchicalNames: ["referencedType", "notUsedMethod"],
            kind: .function,
            sourceLocationRange: notUsedMethodLocationRange,
            definitionUSRs: [notUsedMethodUSR],
        )
        referencedType.functions.append(notUsedMethod)

        let referencedTypeFile = File(
            fullPath: referencedTypeFilePath,
            sourceCode: "",
            abstractDeclarations: [referencedType],
        )

        // root directory

        let directory = Directory(
            fullPath: "",
            subDirectories: [],
            files: [
                referrerFile,
                referencedFile,
                referencedTypeFile,
            ],
        )

        // KeyPath

        let rootDirectoryKeyPath: KeyPath<Directory?, Directory?> = \.?.self

        let referrerFileKeyPath: KeyPath<Directory?, File?> = \.?.files[id: referrerFilePath]
        let referrerStructKeyPath: KeyPath<Directory?, AbstractDeclaration?> = referrerFileKeyPath.appending(path: \.?.abstractDeclarations[id: referrerStructID])
        let referrerMethodKeyPath: KeyPath<Directory?, AbstractDeclaration?> = referrerStructKeyPath.appending(path: \.?.functions[id: referrerMethodID])

        let referencedFileKeyPath: KeyPath<Directory?, File?> = \.?.files[id: referencedFilePath]
        let referencedStructKeyPath: KeyPath<Directory?, AbstractDeclaration?> = referencedFileKeyPath.appending(path: \.?.abstractDeclarations[id: referencedStructID])
        let referencedMethodKeyPath: KeyPath<Directory?, AbstractDeclaration?> = referencedStructKeyPath.appending(path: \.?.functions[id: referencedMethodID])

        let referencedTypeFileKeyPath: KeyPath<Directory?, File?> = \.?.files[id: referencedTypeFilePath]
        let referencedTypeKeyPath: KeyPath<Directory?, AbstractDeclaration?> = referencedTypeFileKeyPath.appending(path: \.?.abstractDeclarations[id: referencedTypeID])
        let notUsedMethodKeyPath: KeyPath<Directory?, AbstractDeclaration?> = referencedTypeKeyPath.appending(path: \.?.functions[id: notUsedMethodID])

        let keyPathTable = KeyPathTable(
            directories: ["": rootDirectoryKeyPath],
            files: [
                referrerFilePath: referrerFileKeyPath,
                referencedFilePath: referencedFileKeyPath,
                referencedTypeFilePath: referencedTypeFileKeyPath,
            ],
            abstractDeclarations: [
                referrerStructUSR: referrerStructKeyPath,
                referrerMethodUSR: referrerMethodKeyPath,
                referencedStructUSR: referencedStructKeyPath,
                referencedMethodUSR: referencedMethodKeyPath,
                referencedTypeUSR: referencedTypeKeyPath,
                notUsedMethodUSR: notUsedMethodKeyPath,
            ],
        )

        // USRStore

        let usrStore = USRStore(
            definitionUSRs: [:],
            referrerUSRs: [
                referencedMethodUSR: [Occurrence(usr: referrerMethodUSR, location: referrerMethodLocationRange.upperBound)],
                referencedTypeUSR: [
                    Occurrence(usr: referrerMethodUSR, location: referrerMethodLocationRange.upperBound),
                    Occurrence(usr: referencedMethodUSR, location: referencedMethodLocationRange.upperBound),
                ],
            ],
            referencedUSRs: [
                referrerMethodUSR: [
                    Occurrence(usr: referencedMethodUSR, location: referencedMethodLocationRange.upperBound),
                    Occurrence(usr: referencedTypeUSR, location: referencedTypeLocationRange.upperBound),
                ],
                referencedMethodUSR: [Occurrence(usr: referencedTypeUSR, location: referencedTypeLocationRange.upperBound)],
            ],
        )

        return RootDirectory(
            directory: directory,
            keyPathTable: keyPathTable,
            usrStore: usrStore,
        )
    }
}
