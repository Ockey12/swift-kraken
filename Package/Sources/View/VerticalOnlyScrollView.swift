//
//  VerticalOnlyScrollView.swift
//  Package
//
//  Created by Ockey on 2025/10/02.
//

import AppKit

final class VerticalOnlyScrollView: NSScrollView {
    override func scrollWheel(with event: NSEvent) {
        let hasHorizontal = abs(event.scrollingDeltaX) > 0.0
        let hasVertical = abs(event.scrollingDeltaY) > 0.0

        // Horizontal-only scroll: propagate to parent and do not handle here
        if hasHorizontal, !hasVertical {
            nextResponder?.scrollWheel(with: event)
            return
        }

        // Handle vertical component normally
        super.scrollWheel(with: event)
    }
}
