//
//  AbstractDeclarationVisitor.swift
//  Package
//
//  Created by Ockey on 2025/09/09.
//

import Dependencies
import IdentifiedCollections
import IndexStore
import Location
import SwiftParser
import SwiftSyntax

final class AbstractDeclarationVisitor: SyntaxVisitor {
    private let fullPath: String
    private let indexStoreResponse: IndexStoreResponse
    private let sourceLocationConverter: SourceLocationConverter
    private var abstractDeclarationsBuffer: [AbstractDeclaration] = []
    private var hierarchicalNames: [String] = []

    var result: IdentifiedArrayOf<AbstractDeclaration> = []

    @Dependency(\.uuid) private var uuid

    init(
        in fullPath: String,
        indexStoreResponse: IndexStoreResponse,
        sourceLocationConverter: SourceLocationConverter,
    ) {
        self.fullPath = fullPath
        self.indexStoreResponse = indexStoreResponse
        self.sourceLocationConverter = sourceLocationConverter

        super.init(viewMode: .sourceAccurate)
    }

    // MARK: struct

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        hierarchicalNames.append(node.name.text)
        let nodeRange = node.sourceRange(converter: sourceLocationConverter)
        let sourceLocationRange = Location(
            fullPath: fullPath,
            line: nodeRange.start.line,
            column: nodeRange.start.column,
        )
            ... Location(
                fullPath: fullPath,
                line: nodeRange.end.line,
                column: nodeRange.end.column,
            )
        var abstractDeclaration = AbstractDeclaration(
            id: uuid(),
            hierarchicalNames: hierarchicalNames,
            kind: .struct,
            sourceLocationRange: sourceLocationRange,
        )

        let nameLocation = node.name.startLocation(converter: sourceLocationConverter)
        let identifierLocation = Location(
            fullPath: fullPath,
            line: nameLocation.line,
            column: nameLocation.column,
        )
        abstractDeclaration.definitionUSRs = indexStoreResponse.definitionUSRs[identifierLocation] ?? [USR(uuid().uuidString)]

        abstractDeclarationsBuffer.append(abstractDeclaration)

        return .visitChildren
    }

    override func visitPost(_: StructDeclSyntax) {
        guard let structDeclaration = abstractDeclarationsBuffer.popLast(),
              case .struct = structDeclaration.kind else {
            return
        }

        hierarchicalNames.removeLast()

        if abstractDeclarationsBuffer.isEmpty {
            result.append(structDeclaration)
        } else {
            let lastIndex = abstractDeclarationsBuffer.endIndex - 1
            abstractDeclarationsBuffer[lastIndex].nestingStructs.append(structDeclaration)
        }
    }

    // MARK: class

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        hierarchicalNames.append(node.name.text)
        let nodeRange = node.sourceRange(converter: sourceLocationConverter)
        let sourceLocationRange = Location(
            fullPath: fullPath,
            line: nodeRange.start.line,
            column: nodeRange.start.column,
        )
            ... Location(
                fullPath: fullPath,
                line: nodeRange.end.line,
                column: nodeRange.end.column,
            )
        var abstractDeclaration = AbstractDeclaration(
            id: uuid(),
            hierarchicalNames: hierarchicalNames,
            kind: .class,
            sourceLocationRange: sourceLocationRange,
        )

        let nameLocation = node.name.startLocation(converter: sourceLocationConverter)
        let identifierLocation = Location(
            fullPath: fullPath,
            line: nameLocation.line,
            column: nameLocation.column,
        )
        abstractDeclaration.definitionUSRs = indexStoreResponse.definitionUSRs[identifierLocation] ?? [USR(uuid().uuidString)]

        abstractDeclarationsBuffer.append(abstractDeclaration)

        return .visitChildren
    }

    override func visitPost(_: ClassDeclSyntax) {
        guard let classDeclaration = abstractDeclarationsBuffer.popLast(),
              case .class = classDeclaration.kind else {
            return
        }

        hierarchicalNames.removeLast()

        if abstractDeclarationsBuffer.isEmpty {
            result.append(classDeclaration)
        } else {
            let lastIndex = abstractDeclarationsBuffer.endIndex - 1
            abstractDeclarationsBuffer[lastIndex].nestingClasses.append(classDeclaration)
        }
    }

    // MARK: enum

    override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        hierarchicalNames.append(node.name.text)
        let nodeRange = node.sourceRange(converter: sourceLocationConverter)
        let sourceLocationRange = Location(
            fullPath: fullPath,
            line: nodeRange.start.line,
            column: nodeRange.start.column,
        )
            ... Location(
                fullPath: fullPath,
                line: nodeRange.end.line,
                column: nodeRange.end.column,
            )
        var abstractDeclaration = AbstractDeclaration(
            id: uuid(),
            hierarchicalNames: hierarchicalNames,
            kind: .enum,
            sourceLocationRange: sourceLocationRange,
        )

        let nameLocation = node.name.startLocation(converter: sourceLocationConverter)
        let identifierLocation = Location(
            fullPath: fullPath,
            line: nameLocation.line,
            column: nameLocation.column,
        )
        abstractDeclaration.definitionUSRs = indexStoreResponse.definitionUSRs[identifierLocation] ?? [USR(uuid().uuidString)]

        abstractDeclarationsBuffer.append(abstractDeclaration)

        return .visitChildren
    }

    override func visitPost(_: EnumDeclSyntax) {
        guard let enumDeclaration = abstractDeclarationsBuffer.popLast(),
              case .enum = enumDeclaration.kind else {
            return
        }

        hierarchicalNames.removeLast()

        if abstractDeclarationsBuffer.isEmpty {
            result.append(enumDeclaration)
        } else {
            let lastIndex = abstractDeclarationsBuffer.endIndex - 1
            abstractDeclarationsBuffer[lastIndex].nestingEnums.append(enumDeclaration)
        }
    }

    // MARK: variable

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        let nodeRange = node.sourceRange(converter: sourceLocationConverter)
        let sourceLocationRange = Location(
            fullPath: fullPath,
            line: nodeRange.start.line,
            column: nodeRange.start.column,
        )
            ... Location(
                fullPath: fullPath,
                line: nodeRange.end.line,
                column: nodeRange.end.column,
            )

        for binding in node.bindings {
            let identifiers = extractIdentifiers(from: binding.pattern)

            for identifier in identifiers {
                var abstractDeclaration = AbstractDeclaration(
                    id: uuid(),
                    hierarchicalNames: hierarchicalNames + [identifier.identifier.text],
                    kind: .variable,
                    sourceLocationRange: sourceLocationRange,
                )

                let nameLocation = identifier.identifier.startLocation(converter: sourceLocationConverter)
                let identifierLocation = Location(
                    fullPath: fullPath,
                    line: nameLocation.line,
                    column: nameLocation.column,
                )
                abstractDeclaration.definitionUSRs = indexStoreResponse.definitionUSRs[identifierLocation] ?? [USR(uuid().uuidString)]

                abstractDeclarationsBuffer.append(abstractDeclaration)
            }
        }

        return .visitChildren
    }

    private func extractIdentifiers(from pattern: PatternSyntax) -> [IdentifierPatternSyntax] {
        var identifiers: [IdentifierPatternSyntax] = []

        switch pattern.as(PatternSyntaxEnum.self) {
        case let .identifierPattern(identifier):
            identifiers.append(identifier)

        case let .tuplePattern(tuple):
            for element in tuple.elements {
                identifiers.append(contentsOf: extractIdentifiers(from: element.pattern))
            }

        case let .valueBindingPattern(valueBinding):
            identifiers.append(contentsOf: extractIdentifiers(from: valueBinding.pattern))

        case .expressionPattern:
            break

        case .isTypePattern:
            break

        case .missingPattern:
            break

        case .wildcardPattern:
            break
        }

        return identifiers
    }

    override func visitPost(_ node: VariableDeclSyntax) {
        var variables: [AbstractDeclaration] = []

        var variableCount = 0
        for binding in node.bindings {
            let identifiers = extractIdentifiers(from: binding.pattern)
            variableCount += identifiers.count
        }

        for _ in 0 ..< variableCount {
            guard let variableDeclaration = abstractDeclarationsBuffer.popLast(),
                  case .variable = variableDeclaration.kind else {
                break
            }
            variables.append(variableDeclaration)
        }

        // Reverse to return to original order
        variables.reverse()

        for variableDeclaration in variables {
            if abstractDeclarationsBuffer.isEmpty {
                result.append(variableDeclaration)
            } else {
                let lastIndex = abstractDeclarationsBuffer.endIndex - 1
                abstractDeclarationsBuffer[lastIndex].variables.append(variableDeclaration)
            }
        }
    }

    // MARK: function

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        hierarchicalNames.append(node.name.text + "()")
        let nodeRange = node.sourceRange(converter: sourceLocationConverter)
        let sourceLocationRange = Location(
            fullPath: fullPath,
            line: nodeRange.start.line,
            column: nodeRange.start.column,
        )
            ... Location(
                fullPath: fullPath,
                line: nodeRange.end.line,
                column: nodeRange.end.column,
            )
        var abstractDeclaration = AbstractDeclaration(
            id: uuid(),
            hierarchicalNames: hierarchicalNames,
            kind: .function,
            sourceLocationRange: sourceLocationRange,
        )

        let nameLocation = node.name.startLocation(converter: sourceLocationConverter)
        let identifierLocation = Location(
            fullPath: fullPath,
            line: nameLocation.line,
            column: nameLocation.column,
        )
        abstractDeclaration.definitionUSRs = indexStoreResponse.definitionUSRs[identifierLocation] ?? [USR(uuid().uuidString)]

        abstractDeclarationsBuffer.append(abstractDeclaration)

        return .visitChildren
    }

    override func visitPost(_: FunctionDeclSyntax) {
        guard let functionDeclaration = abstractDeclarationsBuffer.popLast(),
              case .function = functionDeclaration.kind else {
            return
        }

        hierarchicalNames.removeLast()

        if abstractDeclarationsBuffer.isEmpty {
            result.append(functionDeclaration)
        } else {
            let lastIndex = abstractDeclarationsBuffer.endIndex - 1
            abstractDeclarationsBuffer[lastIndex].functions.append(functionDeclaration)
        }
    }
}
