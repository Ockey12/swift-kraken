//
//  UUIDRepository.swift
//  Package
//
//  Created by Ockey on 2025/09/09.
//

import Foundation

public protocol UUIDRepository {
    mutating func uuid() -> UUID
}

public struct RandomUUIDRepository: UUIDRepository {
    public init() {}

    public func uuid() -> UUID {
        UUID()
    }
}

public struct QueueUUIDRepository: UUIDRepository {
    private var queue: [UUID]

    public init(queue: [UUID]) {
        self.queue = queue
    }

    public mutating func uuid() -> UUID {
        guard !queue.isEmpty else {
            assertionFailure()
            return UUID()
        }
        return queue.removeFirst()
    }
}
