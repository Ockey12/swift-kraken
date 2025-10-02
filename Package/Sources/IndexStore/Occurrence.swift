//
//  Occurrence.swift
//  Package
//
//  Created by Ockey on 2025/09/09.
//

import Location

public struct Occurrence: Equatable, Hashable, Sendable {
    public let usr: USR
    public let location: Location

    public init(usr: USR, location: Location) {
        self.usr = usr
        self.location = location
    }
}
