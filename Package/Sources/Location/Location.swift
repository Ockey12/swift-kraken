//
//  Location.swift
//  Package
//
//  Created by Ockey on 2025/09/08.
//

public struct Location: Equatable, Hashable {
    public let fullPath: String
    public let line: Int
    public let column: Int

    public init(fullPath: String, line: Int, column: Int) {
        self.fullPath = fullPath
        self.line = line
        self.column = column
    }
}

extension Location: Comparable {
    public static func < (lhs: Location, rhs: Location) -> Bool {
        if lhs.line != rhs.line {
            return lhs.line < rhs.line
        }
        return lhs.column < rhs.column
    }
}
