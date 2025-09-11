//
//  AbstractDeclarationVisitorTest.swift
//  Package
//
//  Created by Ockey on 2025/09/09.
//

import CustomDump
import Dependencies
import Foundation
import IdentifiedCollections
import IndexStore
import Location
import SwiftParser
import SwiftSyntax
import TestData
import Testing

@testable import SwiftDeclaration

@Test
func extractObjectFromTestData() throws {
    let fileURL = TestHelper.getTestDataFileURL(fileNameWithExtension: "EmptyDeclaration.swift")
    let fullPath = fileURL.path()
    let sourceCode = try String(contentsOfFile: fileURL.path(), encoding: .utf8)
    let parsedCode = Parser.parse(source: sourceCode)
    let visitor = AbstractDeclarationVisitor(
        in: fileURL.path(),
        usrStore: USRStore(
            definitionUSRs: [:],
            referrerUSRs: [:],
            referencedUSRs: [:]
        ),
        sourceLocationConverter: SourceLocationConverter(
            fileName: fileURL.path(),
            tree: parsedCode
        )
    )

    withDependencies {
        $0.uuid = .incrementing
    } operation: {
        let expectedResult = IdentifiedArray(
            uniqueElements: [
                AbstractDeclaration(
                    id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!,
                    name: "EmptyStruct",
                    sourceLocationRange: Location(fullPath: fullPath, line: 8, column: 1) ... Location(fullPath: fullPath, line: 8, column: 22),
                    kind: .struct
                ),
                AbstractDeclaration(
                    id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
                    name: "EmptyClass",
                    sourceLocationRange: Location(fullPath: fullPath, line: 10, column: 1) ... Location(fullPath: fullPath, line: 10, column: 20),
                    kind: .class
                ),
                AbstractDeclaration(
                    id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
                    name: "EmptyEnum",
                    sourceLocationRange: Location(fullPath: fullPath, line: 12, column: 1) ... Location(fullPath: fullPath, line: 12, column: 18),
                    kind: .enum
                ),
                AbstractDeclaration(
                    id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
                    name: "emptyVariable",
                    sourceLocationRange: Location(fullPath: fullPath, line: 14, column: 1) ... Location(fullPath: fullPath, line: 14, column: 22),
                    kind: .variable
                ),
                AbstractDeclaration(
                    id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
                    name: "emptyFunction",
                    sourceLocationRange: Location(fullPath: fullPath, line: 16, column: 1) ... Location(fullPath: fullPath, line: 16, column: 24),
                    kind: .function
                ),
            ]
        )

        visitor.walk(parsedCode)

        expectNoDifference(expectedResult, visitor.result)
    }


}
