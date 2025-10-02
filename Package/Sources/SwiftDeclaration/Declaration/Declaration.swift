//
//  Declaration.swift
//  Package
//
//  Created by Ockey on 2025/09/09.
//

import Foundation
import IdentifiedCollections
import IndexStore
import Location

public struct Declaration: Identifiable, Equatable, Hashable, Sendable {
    public let id: UUID
    public var hierarchicalNames: [String]
    public var name: String? {
        hierarchicalNames.last
    }

    public var joinedHierarchicalName: String {
        hierarchicalNames.joined(separator: ".")
    }

    public let sourceLocationRange: ClosedRange<Location>
    public var definitionUSRs: [USR]
    public var callersUSRs: Set<USR>
    public var calleesUSRs: Set<USR>

    public var variables: IdentifiedArrayOf<Declaration>
    public var functions: IdentifiedArrayOf<Declaration>
    public var cases: IdentifiedArrayOf<Declaration>

    public var nestingStructs: IdentifiedArrayOf<Declaration>
    public var nestingClasses: IdentifiedArrayOf<Declaration>
    public var nestingEnums: IdentifiedArrayOf<Declaration>

    public let kind: Kind

    private(set) var sortedChildren: [Declaration] = []

    public init(
        id: UUID,
        hierarchicalNames: [String],
        kind: Kind,
        sourceLocationRange: ClosedRange<Location>,
        definitionUSRs: [USR] = [],
        callersUSRs: Set<USR> = [],
        calleesUSRs: Set<USR> = [],
        variables: IdentifiedArrayOf<Declaration> = [],
        functions: IdentifiedArrayOf<Declaration> = [],
        cases: IdentifiedArrayOf<Declaration> = [],
        nestingStructs: IdentifiedArrayOf<Declaration> = [],
        nestingClasses: IdentifiedArrayOf<Declaration> = [],
        nestingEnums: IdentifiedArrayOf<Declaration> = [],
    ) {
        self.id = id
        self.hierarchicalNames = hierarchicalNames
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

    func generateKeyPath(fromRootDirectory keyPath: KeyPath<Directory?, Declaration?>) -> KeyPathTable {
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

    mutating func updatedSortedChildren() {
        var array = variables.elements
        array.append(contentsOf: functions)
        array.append(contentsOf: cases)
        array.append(contentsOf: nestingStructs)
        array.append(contentsOf: nestingClasses)
        array.append(contentsOf: nestingEnums)
        sortedChildren = array.sorted(by: {
            $0.sourceLocationRange.lowerBound < $1.sourceLocationRange.lowerBound
        })
    }
}

public extension Declaration {
    enum Kind: Sendable {
        case `struct`
        case `class`
        case `enum`
        case variable
        case function
        case `case`
    }
}

private extension Declaration {
    enum SearchedProperty: CaseIterable {
        case variables
        case functions
        case cases
        case nestingStructs
        case nestingClasses
        case nestingEnums

        var keyPath: KeyPath<Declaration, IdentifiedArrayOf<Declaration>> {
            switch self {
            case .variables: \.variables
            case .functions: \.functions
            case .cases: \.cases
            case .nestingStructs: \.nestingStructs
            case .nestingClasses: \.nestingClasses
            case .nestingEnums: \.nestingEnums
            }
        }

        func keyPath(withID id: UUID) -> KeyPath<Declaration?, Declaration?> {
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
