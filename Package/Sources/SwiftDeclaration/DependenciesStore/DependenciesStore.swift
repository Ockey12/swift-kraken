//
//  DependenciesStore.swift
//  Package
//
//  Created by Ockey on 2025/09/25.
//

import IndexStore

public struct DependenciesStore: Equatable, Sendable {
    /// Store, in a dictionary, the USRs of other symbols that reference a symbol X. The key is the USR of symbol X, and the value is the USRs of the symbols that reference X.
    public var referrerUSRs: [USR: [USR]]

    /// Store, in a dictionary, the USRs of other symbols that a symbol X references. The key is the USR of symbol X, and the value is the USRs of the symbols referenced by X.
    public var referencedUSRs: [USR: [USR]]

    mutating func merge(with other: Self) {
        referrerUSRs.merge(other.referrerUSRs) { first, second in
            first + second
        }

        referencedUSRs.merge(other.referencedUSRs) { first, second in
            first + second
        }
    }
}
