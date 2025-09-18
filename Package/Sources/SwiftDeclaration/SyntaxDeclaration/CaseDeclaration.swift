////
////  CaseDeclaration.swift
////  Package
////
////  Created by Ockey on 2025/09/09.
////
//
// import Foundation
// import Location
//
// public struct CaseDeclaration: Declaration, Equatable {
//    public let id: UUID
//    public let name: String
//    public let sourceLocationRange: ClosedRange<Location>
//    public var fullPath: String {
//        sourceLocationRange.lowerBound.fullPath
//    }
//
//    static func generate(from abstractDeclaration: AbstractDeclaration) -> Self {
//        .init(
//            id: abstractDeclaration.id,
//            name: abstractDeclaration.name,
//            sourceLocationRange: abstractDeclaration.sourceLocationRange,
//        )
//    }
// }
