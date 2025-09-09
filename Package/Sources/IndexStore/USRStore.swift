//
//  USRStore.swift
//  Package
//
//  Created by Ockey on 2025/09/08.
//

import Declaration

public struct USRStore: Equatable {
    var definitionUSRs: [Location: Set<USR>]

    /// Store, in a dictionary, the USRs of other symbols that reference a symbol X. The key is the USR of symbol X, and the value is the USRs of the symbols that reference X.
    var referrerUSRs: [USR: Set<Occurrence>]

    /// Store, in a dictionary, the USRs of other symbols that a symbol X references. The key is the USR of symbol X, and the value is the USRs of the symbols referenced by X.
    var referencedUSRs: [USR: Set<Occurrence>]
}
