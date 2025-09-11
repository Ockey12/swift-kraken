//
//  RootDirectoryClient.swift
//  Package
//
//  Created by Ockey on 2025/09/11.
//

import CustomDump
import Dependencies
import Foundation
import IndexStore
import Location
import TestData
import Testing

@testable import SwiftDeclaration

@Test
func rootDirectoryClientTest() async throws {
    let rootDirectoryURL = TestHelper.rootDirectoryURL
    let rootDirectoryPath = rootDirectoryURL.path()
    let indexStoreURL = try #require(TestHelper.findIndexStorePath())

    // MARK: SubDirectory

    let subDirectoryURL = rootDirectoryURL.appending(component: "SubDirectory/")
    let subDirectoryPath = subDirectoryURL.path()
    let filePathInSubDirectory = subDirectoryURL.appending(component: "FileInSubDirectory.swift").path()

    let subCounterViewModelID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
    let subCounterViewModelUSR = USR("s:8TestData19SubCounterViewModelC")
    let subCounterViewModel = AbstractDeclaration(
        id: subCounterViewModelID,
        name: "SubCounterViewModel",
        kind: .class,
        sourceLocationRange: Location(
            fullPath: filePathInSubDirectory,
            line: 8,
            column: 1,
        )
            ... Location(
                fullPath: filePathInSubDirectory,
                line: 8,
                column: 47,
            ),
        definitionUSRs: [subCounterViewModelUSR],
    )

    let fileInSubDirectory = File(
        fullPath: filePathInSubDirectory,
        sourceCode: """
        //
        //  FileInSubDirectory.swift
        //  Package
        //
        //  Created by Ockey on 2025/09/11.
        //

        class SubCounterViewModel: CounterViewModel {}

        """,
        abstractDeclarations: [subCounterViewModel],
    )

    let subDirectory = Directory(
        fullPath: subDirectoryPath,
        subDirectories: [],
        files: [fileInSubDirectory],
    )

    // MARK: RootDirectory

    let filePathInRootDirectory = rootDirectoryURL.appending(component: "FileInRootDirectory.swift").path()

    let countID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
    let countUSR = USR("s:8TestData16CounterViewModelC5countSivp")
    let count = AbstractDeclaration(
        id: countID,
        name: "count",
        kind: .variable,
        sourceLocationRange: Location(
            fullPath: filePathInRootDirectory,
            line: 12,
            column: 5,
        )
            ... Location(
                fullPath: filePathInRootDirectory,
                line: 12,
                column: 18,
            ),
        definitionUSRs: [countUSR],
    )

    let incrementID = UUID(uuidString: "00000000-0000-0000-0000-000000000003")!
    let incrementUSR = USR("s:8TestData16CounterViewModelC9incrementyyF")
    let increment = AbstractDeclaration(
        id: incrementID,
        name: "increment",
        kind: .function,
        sourceLocationRange: Location(
            fullPath: filePathInRootDirectory,
            line: 14,
            column: 5,
        )
            ... Location(
                fullPath: filePathInRootDirectory,
                line: 16,
                column: 6,
            ),
        definitionUSRs: [incrementUSR],
    )

    let counterViewModelID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    let counterViewModelUSR = USR("s:8TestData16CounterViewModelC")
    let counterViewModelInitUSR = USR("s:8TestData16CounterViewModelCACycfc")
    let counterViewModel = AbstractDeclaration(
        id: counterViewModelID,
        name: "CounterViewModel",
        kind: .class,
        sourceLocationRange: Location(
            fullPath: filePathInRootDirectory,
            line: 10,
            column: 1,
        )
            ... Location(
                fullPath: filePathInRootDirectory,
                line: 17,
                column: 2,
            ),
        definitionUSRs: [
            counterViewModelUSR,
            counterViewModelInitUSR,
        ],
        variables: [count],
        functions: [increment],
    )

    let fileInRootDirectory = File(
        fullPath: filePathInRootDirectory,
        sourceCode: """
        //
        //  FileInRootDirectory.swift
        //  Package
        //
        //  Created by Ockey on 2025/09/11.
        //

        import SwiftUI

        @Observable
        class CounterViewModel {
            var count = 0

            func increment() {
                count += 1
            }
        }

        """,
        abstractDeclarations: [counterViewModel],
    )

    try await withDependencies {
        $0.uuid = .incrementing
        $0.rootDirectoryClient = .liveValue
        $0.usrStoreClient = .liveValue
    } operation: {
        @Dependency(\.rootDirectoryClient) var rootDirectoryClient
        let response = try await rootDirectoryClient.extract(rootDirectoryURL: rootDirectoryURL, indexStoreURL: indexStoreURL)

        let expectedResult = RootDirectory(
            directory: Directory(
                fullPath: rootDirectoryPath,
                subDirectories: [subDirectory],
                files: [fileInRootDirectory],
            ),
            keyPathTable: KeyPathTable(
                directories: [
                    rootDirectoryPath: \.self,
                    subDirectoryPath: \.?.subDirectories[id: subDirectoryPath],
                ],
                files: [
                    filePathInRootDirectory: \.?.files[id: filePathInRootDirectory],
                    filePathInSubDirectory: \.?.subDirectories[id: subDirectoryPath]?.files[id: filePathInSubDirectory],
                ],
                abstractDeclarations: [
                    counterViewModelUSR: \.?.files[id: filePathInRootDirectory]?.abstractDeclarations[id: counterViewModelID],
                    counterViewModelInitUSR: \.?.files[id: filePathInRootDirectory]?.abstractDeclarations[id: counterViewModelID],
                    countUSR: \.?.files[id: filePathInRootDirectory]?.abstractDeclarations[id: counterViewModelID]?.variables[id: countID],
                    incrementUSR: \.?.files[id: filePathInRootDirectory]?.abstractDeclarations[id: counterViewModelID]?.functions[id: incrementID],
                    subCounterViewModelUSR: \.?.subDirectories[id: subDirectoryPath]?.files[id: filePathInSubDirectory]?.abstractDeclarations[id: subCounterViewModelID],
                ],
            ),
        )

        expectNoDifference(expectedResult, response)
    }
}
