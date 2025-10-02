//
//  VerticalDividerView.swift
//  Package
//
//  Created by Ockey on 2025/10/02.
//

import AppKit

final class VerticalDividerView: NSView {
    var onMouseDown: ((CGFloat) -> Void)?
    var onDragged: ((CGFloat) -> Void)?
    var onMouseUp: (() -> Void)?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        translatesAutoresizingMaskIntoConstraints = false
        widthAnchor.constraint(equalToConstant: 5).isActive = true
        wantsLayer = true
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .resizeLeftRight)
    }

    override func mouseDown(with event: NSEvent) {
        onMouseDown?(event.locationInWindow.x)
        NSCursor.resizeLeftRight.push()
        window?.disableCursorRects()
    }

    override func mouseUp(with _: NSEvent) {
        onMouseUp?()
        window?.enableCursorRects()
        NSCursor.pop()
        window?.invalidateCursorRects(for: self)
    }

    override func mouseDragged(with event: NSEvent) {
        onDragged?(event.locationInWindow.x)
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        needsDisplay = true
    }

    override func updateLayer() {
        wantsLayer = true
        layer?.backgroundColor = NSColor(named: "VerticalDivider", bundle: .module)?.cgColor
    }
}
