//
//  DeclarationCellState.swift
//  Package
//
//  Created by Ockey on 2025/09/15.
//

import Foundation
import IdentifiedCollections
import SwiftDeclaration

struct DeclarationCellState: Identifiable {
    var id: UUID {
        declaration.id
    }

    private let declaration: AbstractDeclaration

    init(declaration: AbstractDeclaration) {
        self.declaration = declaration
    }

    var displayName: String {
        declaration.name
    }

    var children: IdentifiedArrayOf<AbstractDeclaration> {
        var array = declaration.variables
        array.append(contentsOf: declaration.functions)
        array.append(contentsOf: declaration.cases)
        array.append(contentsOf: declaration.nestingStructs)
        array.append(contentsOf: declaration.nestingClasses)
        array.append(contentsOf: declaration.nestingEnums)
        array.sort { $0.sourceLocationRange.upperBound < $1.sourceLocationRange.upperBound }
        return array
    }

    var hasChildren: Bool {
        !children.isEmpty
    }
}

import IndexStore
import Location

extension DeclarationCellState {
    static var dummy: Self {
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

        return DeclarationCellState(declaration: referrerStruct)
    }
}
