//
//  SwiftDeclaration.swift
//  Package
//
//  Created by Ockey on 2025/09/09.
//

import Foundation

public enum SwiftDeclaration: Identifiable, Equatable {
    case `struct`(StructDeclaration)
    case `class`(ClassDeclaration)
    case `enum`(EnumDeclaration)
    case variable(VariableDeclaration)
    case function(FunctionDeclaration)
    case `case`(CaseDeclaration)

    public var id: UUID {
        switch self {
        case let .struct(structDeclaration):
            structDeclaration.id
        case let .class(classDeclaration):
            classDeclaration.id
        case let .enum(enumDeclaration):
            enumDeclaration.id
        case let .variable(variableDeclaration):
            variableDeclaration.id
        case let .function(functionDeclaration):
            functionDeclaration.id
        case let .case(caseDeclaration):
            caseDeclaration.id
        }
    }
}
