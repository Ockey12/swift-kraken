//
//  USRStore.swift
//  Package
//
//  Created by Ockey on 2025/09/08.
//

import Location

public struct USRStore: Equatable {
    public var definitionUSRs: [Location: Set<USR>]

    /// Store, in a dictionary, the USRs of other symbols that reference a symbol X. The key is the USR of symbol X, and the value is the USRs of the symbols that reference X.
    public var referrerUSRs: [USR: Set<Occurrence>]

    /// Store, in a dictionary, the USRs of other symbols that a symbol X references. The key is the USR of symbol X, and the value is the USRs of the symbols referenced by X.
    public var referencedUSRs: [USR: Set<Occurrence>]

    public init(
        definitionUSRs: [Location: Set<USR>],
        referrerUSRs: [USR: Set<Occurrence>],
        referencedUSRs: [USR: Set<Occurrence>],
    ) {
        self.definitionUSRs = definitionUSRs
        self.referrerUSRs = referrerUSRs
        self.referencedUSRs = referencedUSRs
    }
}
