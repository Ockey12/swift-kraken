////
////  EnumDeclaration.swift
////  Package
////
////  Created by Ockey on 2025/09/09.
////
//
// import Foundation
// import IdentifiedCollections
// import Location
//
// public struct EnumDeclaration: Declaration, Equatable {
//    public let id: UUID
//    public let name: String
//    public let sourceLocationRange: ClosedRange<Location>
//    public var fullPath: String {
//        sourceLocationRange.lowerBound.fullPath
//    }
//
//    public let cases: IdentifiedArrayOf<CaseDeclaration>
//    public let variables: IdentifiedArrayOf<VariableDeclaration>
//    public let functions: IdentifiedArrayOf<FunctionDeclaration>
//
//    public let nestingStructs: IdentifiedArrayOf<StructDeclaration>
//    public let nestingClasses: IdentifiedArrayOf<ClassDeclaration>
//    public let nestingEnums: IdentifiedArrayOf<EnumDeclaration>
//
//    static func generate(from abstractDeclaration: AbstractDeclaration) -> Self {
//        .init(
//            id: abstractDeclaration.id,
//            name: abstractDeclaration.name,
//            sourceLocationRange: abstractDeclaration.sourceLocationRange,
//            cases: IdentifiedArray(uniqueElements: abstractDeclaration.cases.map { CaseDeclaration.generate(from: $0) }),
//            variables: IdentifiedArray(uniqueElements: abstractDeclaration.variables.map { VariableDeclaration.generate(from: $0) }),
//            functions: IdentifiedArray(uniqueElements: abstractDeclaration.functions.map { FunctionDeclaration.generate(from: $0) }),
//            nestingStructs: IdentifiedArray(uniqueElements: abstractDeclaration.nestingStructs.map { StructDeclaration.generate(from: $0) }),
//            nestingClasses: IdentifiedArray(uniqueElements: abstractDeclaration.nestingClasses.map { ClassDeclaration.generate(from: $0) }),
//            nestingEnums: IdentifiedArray(uniqueElements: abstractDeclaration.nestingEnums.map { EnumDeclaration.generate(from: $0) }),
//        )
//    }
// }
