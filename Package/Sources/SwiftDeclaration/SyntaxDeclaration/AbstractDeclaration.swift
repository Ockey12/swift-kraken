//
//  AbstractDeclaration.swift
//  Package
//
//  Created by Ockey on 2025/09/09.
//

import Foundation
import IdentifiedCollections
import IndexStore
import Location

struct AbstractDeclaration: Identifiable, Equatable, Hashable {
    let id: UUID
    let name: String
    let sourceLocationRange: ClosedRange<Location>
    var definitionUSRs: Set<USR>
    var callersUSRs: Set<USR>
    var calleesUSRs: Set<USR>

    var variables: IdentifiedArrayOf<AbstractDeclaration>
    var functions: IdentifiedArrayOf<AbstractDeclaration>
    var cases: IdentifiedArrayOf<AbstractDeclaration>

    var nestingStructs: IdentifiedArrayOf<AbstractDeclaration>
    var nestingClasses: IdentifiedArrayOf<AbstractDeclaration>
    var nestingEnums: IdentifiedArrayOf<AbstractDeclaration>

    let kind: Kind

    var swiftDeclaration: SwiftDeclaration {
        switch kind {
        case .struct:
            .struct(StructDeclaration.generate(from: self))
        case .class:
            .class(ClassDeclaration.generate(from: self))
        case .enum:
            .enum(EnumDeclaration.generate(from: self))
        case .variable:
            .variable(VariableDeclaration.generate(from: self))
        case .function:
            .function(FunctionDeclaration.generate(from: self))
        case .case:
            .case(CaseDeclaration.generate(from: self))
        }
    }

    init(
        id: UUID,
        name: String,
        kind: Kind,
        sourceLocationRange: ClosedRange<Location>,
        definitionUSRs: Set<USR> = [],
        callersUSRs: Set<USR> = [],
        calleesUSRs: Set<USR> = [],
        variables: IdentifiedArrayOf<AbstractDeclaration> = [],
        functions: IdentifiedArrayOf<AbstractDeclaration> = [],
        cases: IdentifiedArrayOf<AbstractDeclaration> = [],
        nestingStructs: IdentifiedArrayOf<AbstractDeclaration> = [],
        nestingClasses: IdentifiedArrayOf<AbstractDeclaration> = [],
        nestingEnums: IdentifiedArrayOf<AbstractDeclaration> = [],
    ) {
        self.id = id
        self.name = name
        self.sourceLocationRange = sourceLocationRange
        self.definitionUSRs = definitionUSRs
        self.callersUSRs = callersUSRs
        self.calleesUSRs = calleesUSRs
        self.variables = variables
        self.functions = functions
        self.cases = cases
        self.nestingStructs = nestingStructs
        self.nestingClasses = nestingClasses
        self.nestingEnums = nestingEnums
        self.kind = kind
    }

    func generateKeyPath(fromRootDirectory keyPath: KeyPath<Directory?, AbstractDeclaration?>) -> KeyPathTable {
        var table = KeyPathTable(directories: [:], files: [:], abstractDeclarations: [:])

        definitionUSRs.forEach { usr in
            table.abstractDeclarations[usr] = keyPath
        }

        for property in SearchedProperty.allCases {
            for declaration in self[keyPath: property.keyPath] {
                table.merge(declaration.generateKeyPath(
                    fromRootDirectory: keyPath.appending(path: property.keyPath(withID: declaration.id)),
                ))
            }
        }

        return table
    }
}

extension AbstractDeclaration {
    enum Kind {
        case `struct`
        case `class`
        case `enum`
        case variable
        case function
        case `case`
    }
}

private extension AbstractDeclaration {
    enum SearchedProperty: CaseIterable {
        case variables
        case functions
        case cases
        case nestingStructs
        case nestingClasses
        case nestingEnums

        var keyPath: KeyPath<AbstractDeclaration, IdentifiedArrayOf<AbstractDeclaration>> {
            switch self {
            case .variables: \.variables
            case .functions: \.functions
            case .cases: \.cases
            case .nestingStructs: \.nestingStructs
            case .nestingClasses: \.nestingClasses
            case .nestingEnums: \.nestingEnums
            }
        }

        func keyPath(withID id: UUID) -> KeyPath<AbstractDeclaration?, AbstractDeclaration?> {
            switch self {
            case .variables: \.?.variables[id: id]
            case .functions: \.?.functions[id: id]
            case .cases: \.?.cases[id: id]
            case .nestingStructs: \.?.nestingStructs[id: id]
            case .nestingClasses: \.?.nestingClasses[id: id]
            case .nestingEnums: \.?.nestingEnums[id: id]
            }
        }
    }
}
