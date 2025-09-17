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
