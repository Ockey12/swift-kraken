//
//  FileInRootDirectory.swift
//  Package
//
//  Created by Ockey on 2025/09/11.
//

import SwiftUI

@Observable
class CounterViewModel {
    var count = 0

    func increment() {
        count += 1
    }
}
