//
//  AbstractDeclarationVisitorTest.swift
//  Package
//
//  Created by Ockey on 2025/09/09.
//

import CustomDump
import Foundation
import IdentifiedCollections
import IndexStore
import Location
import SwiftParser
import SwiftSyntax
import TestData
import Testing
import UUID

@testable import SwiftDeclaration

@Test
func extractObjectFromTestData() throws {
    let fileURL = TestHelper.getTestDataFileURL(fileNameWithExtension: "EmptyDeclaration.swift")
    let fullPath = fileURL.path()
    let sourceCode = try String(contentsOfFile: fileURL.path(), encoding: .utf8)
    let parsedCode = Parser.parse(source: sourceCode)
    let uuids = [
        UUID(uuidString: "00000000-0000-0000-0000-000000000000")!,
        UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
        UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
        UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
        UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
    ]
    let visitor = AbstractDeclarationVisitor(
        in: fileURL.path(),
        usrStore: IndexStoreUseCase.Response(
            definitionUSRs: [:],
            referrerUSRs: [:],
            referencedUSRs: [:]
        ),
        sourceLocationConverter: SourceLocationConverter(
            fileName: fileURL.path(),
            tree: parsedCode
        ),
        uuidRepository: QueueUUIDRepository(queue: uuids)
    )

    visitor.walk(parsedCode)

    let expectedResult = IdentifiedArray(
        uniqueElements: [
            AbstractDeclaration(
                id: uuids[0],
                name: "EmptyStruct",
                sourceLocationRange: Location(fullPath: fullPath, line: 8, column: 1) ... Location(fullPath: fullPath, line: 8, column: 22),
                kind: .struct
            ),
            AbstractDeclaration(
                id: uuids[1],
                name: "EmptyClass",
                sourceLocationRange: Location(fullPath: fullPath, line: 10, column: 1) ... Location(fullPath: fullPath, line: 10, column: 20),
                kind: .class
            ),
            AbstractDeclaration(
                id: uuids[2],
                name: "EmptyEnum",
                sourceLocationRange: Location(fullPath: fullPath, line: 12, column: 1) ... Location(fullPath: fullPath, line: 12, column: 18),
                kind: .enum
            ),
            AbstractDeclaration(
                id: uuids[3],
                name: "emptyVariable",
                sourceLocationRange: Location(fullPath: fullPath, line: 14, column: 1) ... Location(fullPath: fullPath, line: 14, column: 22),
                kind: .variable
            ),
            AbstractDeclaration(
                id: uuids[4],
                name: "emptyFunction",
                sourceLocationRange: Location(fullPath: fullPath, line: 16, column: 1) ... Location(fullPath: fullPath, line: 16, column: 24),
                kind: .function
            ),
        ]
    )

    expectNoDifference(expectedResult, visitor.result)
}
