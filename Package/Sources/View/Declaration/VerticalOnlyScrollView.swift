//
//  VerticalOnlyScrollView.swift
//  Package
//
//  Created by Ockey on 2025/09/16.
//

import AppKit

final class VerticalOnlyScrollView: NSScrollView {
    override func scrollWheel(with event: NSEvent) {
        // Delegate horizontal scrolling to the parent view.
        let absX = abs(event.scrollingDeltaX)
        let absY = abs(event.scrollingDeltaY)
        if absX > absY {
            nextResponder?.scrollWheel(with: event)
            return
        }
        super.scrollWheel(with: event)
    }
}
