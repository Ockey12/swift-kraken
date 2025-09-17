//
//  ResizableColumnsView.swift
//  Package
//
//  Created by Ockey on 2025/09/17.
//

import AppKit

final class ResizableColumnsView: NSView {
    struct Column {
        let contentView: NSView
        var width: CGFloat
    }

    private var columns: [Column] = []
    private var dividerWidth: CGFloat = 1
    private var dividerColor: NSColor = .separatorColor
    private var columnContainers: [ColumnContainerView] = []
    private let minColumnWidth: CGFloat = 300

    private var draggingDividerIndex: Int?
    private var dragStartLocationX: CGFloat = 0
    private var dragStartWidthOfLeftColumn: CGFloat = 0
    private var dragStartWidthOfAdjustment: CGFloat = 0

    override var isFlipped: Bool { true }

    init(columns: [Column]) {
        self.columns = columns
        super.init(frame: .zero)

        wantsLayer = true
        setupSubviews()
        ensureTrailingAdjustmentColumn()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
    }

    private func setupSubviews() {
        for column in columns {
            let container = ColumnContainerView(contentView: column.contentView)
            addSubview(container)
            columnContainers.append(container)
        }
    }

    // MARK: Array operations

    func appendColumn(_ column: Column) {
        if let adjustmentColumnIndex = indexOfAdjustment() {
            columns.insert(column, at: adjustmentColumnIndex)
            let container = ColumnContainerView(contentView: column.contentView)
            addSubview(container)
            columnContainers.insert(container, at: adjustmentColumnIndex)

            // Reset the width of the rightmost adjustment column to 0.
            if isAdjustmentColumn(adjustmentColumnIndex + 1) {
                var adjustmentColumn = columns[adjustmentColumnIndex + 1]
                adjustmentColumn.width = 0
                columns[adjustmentColumnIndex + 1] = adjustmentColumn
            } else if let newAdjustmentColumnIndex = indexOfAdjustment() {
                var adjustmentColumn = columns[newAdjustmentColumnIndex]
                adjustmentColumn.width = 0
                columns[newAdjustmentColumnIndex] = adjustmentColumn
            }
        } else {
            columns.append(column)
            let container = ColumnContainerView(contentView: column.contentView)
            addSubview(container)
            columnContainers.append(container)
            ensureTrailingAdjustmentColumn()
        }

        needsLayout = true
        layoutSubtreeIfNeeded()
        needsDisplay = true
    }

    private func indexOfAdjustment() -> Int? {
        for (index, column) in columns.enumerated() {
            if column.contentView is AdjustmentSpacerView {
                return index
            }
        }

        return nil
    }

    private func isAdjustmentColumn(_ index: Int) -> Bool {
        guard index >= 0,
              index < columns.count else {
            return false
        }
        return columns[index].contentView is AdjustmentSpacerView
    }

    private func ensureTrailingAdjustmentColumn() {
        if let last = columns.last,
           last.contentView is AdjustmentSpacerView {
            // An AdjustmentSpacerView already exists at the end.
            return
        }

        let spacer = Column(contentView: AdjustmentSpacerView(), width: 0)
        columns.append(spacer)
        let container = ColumnContainerView(contentView: spacer.contentView)
        addSubview(container)
        columnContainers.append(container)
    }

    /// Delete all columns to the right of the specified index.
    func removeColumns(after index: Int) {
        guard let adjustmentColumnIndex = indexOfAdjustment() else {
            return
        }

        let start = max(index + 1, 0)

        let end = adjustmentColumnIndex - 1

        guard start <= end else {
            return
        }

        // To keep the adjustment column, delete from the end toward the beginning.
        for i in stride(from: end, to: start, by: -1) {
            if columnContainers.indices.contains(i) {
                columnContainers[i].removeFromSuperview()
                columnContainers.remove(at: i)
            }
            if columns.indices.contains(i) {
                columns.remove(at: i)
            }
        }

        needsLayout = true
        layoutSubtreeIfNeeded()
        needsDisplay = true
    }

    // MARK: Layout

    override func layout() {
        super.layout()
        layoutColumns()
    }

    private func layoutColumns() {
        var currentX: CGFloat = 0
        for (index, column) in columns.enumerated() {
            let view = columnContainers[index]
            let width = isAdjustmentColumn(index) ? max(0, column.width) : max(minColumnWidth, column.width)
            view.frame = NSRect(x: currentX, y: 0, width: width, height: bounds.height)
            currentX += width

            // Do not place the divider at the end.
            if index < columns.count - 1 {
                currentX += dividerWidth
            }
        }

        let widthsSum = columns.enumerated().reduce(CGFloat(0)) { partialResult, enumerated in
            let (index, column) = enumerated
            let width = isAdjustmentColumn(index) ? max(0, column.width) : max(minColumnWidth, column.width)
            return partialResult + width
        }
        let totalWidth = widthsSum + CGFloat(max(columns.count - 1, 0)) * dividerWidth
        var newFrame = frame
        var mutated = false
        if newFrame.size.width != totalWidth {
            newFrame.size.width = totalWidth
            mutated = true
        }

        // Always match the height to the superview.
        if let superview,
           newFrame.size.height != superview.bounds.height {
            newFrame.size.height = superview.bounds.height
            mutated = true
        }

        if mutated {
            frame = newFrame
        }
    }

    // MARK: Divider

    /// The index corresponds to the column adjacent on the left of this divider.
    private func dividerRect(at index: Int) -> NSRect {
        var x: CGFloat = 0
        for i in 0...index {
            let width = isAdjustmentColumn(i) ? max(0, columns[i].width) : max(minColumnWidth, columns[i].width)
            x += width
            if i < index { x += dividerWidth}
        }
        return NSRect(x: x, y: 0, width: dividerWidth, height: bounds.height)
    }

    private func dividerIndex(at point: NSPoint) -> Int? {
        guard columns.count >= 2 else {
            return nil
        }

        for i in 0..<(columns.count - 1) {
            // Expand the hitbox by 2 units to the left and right beyond the visual bounds.
            if dividerRect(at: i).insetBy(dx: -2, dy: 0).contains(point) {
                return i
            }
        }
        return nil
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        dividerColor.setFill()
        if columns.count >= 2 {
            for i in 0..<(columns.count - 1) {
                dividerRect(at: i).fill()
            }
        }
    }

    // MARK: Mouse event

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        window?.invalidateCursorRects(for: self)
    }

    override func resetCursorRects() {
        super.resetCursorRects()
        if columns.count >= 2 {
            for i in 0..<(columns.count - 1) {
                addCursorRect(dividerRect(at: i), cursor: .columnResize)
            }
        }
    }

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        if let index = dividerIndex(at: point) {
            draggingDividerIndex = index
            dragStartLocationX = point.x
            dragStartWidthOfLeftColumn = max(minColumnWidth, columns[index].width)
            if let adjustmentColumnIndex = indexOfAdjustment() {
                dragStartWidthOfAdjustment = max(0, columns[adjustmentColumnIndex].width)
            } else {
                dragStartWidthOfAdjustment = 0
            }
        } else {
            super.mouseDown(with: event)
        }
    }

    override func mouseDragged(with event: NSEvent) {
        guard let draggingDividerIndex else {
            return
        }
        let point = convert(event.locationInWindow, from: nil)
        let delta = point.x - dragStartLocationX

        if isAdjustmentColumn(draggingDividerIndex) {
            var adjustmentColumn = columns[draggingDividerIndex]
            let newWidth = max(0, dragStartWidthOfAdjustment + delta)
            adjustmentColumn.width = newWidth
            columns[draggingDividerIndex] = adjustmentColumn
        } else {
            // Change the width of the column adjacent to the left side of the divider, and also adjust the width of the adjustment column so that the total width remains unchanged.
            var leftColumn = columns[draggingDividerIndex]
            let newWidth = max(minColumnWidth, dragStartWidthOfLeftColumn + delta)
            let deltaChange = newWidth - dragStartWidthOfLeftColumn
            leftColumn.width = newWidth
            columns[draggingDividerIndex] = leftColumn

            if let adjustmentColumnIndex = indexOfAdjustment() {
                var adjustmentColumn = columns[adjustmentColumnIndex]
                let newAdjustmentWidth = max(0, dragStartWidthOfAdjustment - deltaChange)
                adjustmentColumn.width = newAdjustmentWidth
                columns[adjustmentColumnIndex] = adjustmentColumn
            }
        }

        needsLayout = true
        layoutSubtreeIfNeeded()
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        draggingDividerIndex = nil
    }

    // MARK: Output column size

    func frameOfColumn(at index: Int) -> NSRect? {
        guard columns.indices.contains(index) else {
            return nil
        }

        var x: CGFloat = 0
        for i in 0..<index {
            let width = isAdjustmentColumn(i) ? max(0, columns[i].width) : max(minColumnWidth, columns[i].width)
            x += width + dividerWidth
        }
        let width = isAdjustmentColumn(index) ? max(0, columns[index].width) : max(minColumnWidth, columns[index].width)
        return NSRect(x: x, y: 0, width: width, height: bounds.height)
    }

    func widthOfColumn(at index: Int) -> CGFloat? {
        guard columns.indices.contains(index) else {
            return nil
        }
        return isAdjustmentColumn(index) ? max(0, columns[index].width) : max(minColumnWidth, columns[index].width)
    }
}

private final class ColumnContainerView: NSView {
    let contentContainerView: NSView

    init(contentView: NSView) {
        self.contentContainerView = NSView()
        super.init(frame: .zero)
        setup(contentView: contentView)
    }

    required init?(coder: NSCoder) {
        self.contentContainerView = NSView()
        super.init(coder: coder)
        setup(contentView: NSView())
    }

    private func setup(contentView: NSView) {
        wantsLayer = true
        addSubview(contentContainerView)

        contentView.translatesAutoresizingMaskIntoConstraints = true
        contentContainerView.addSubview(contentView)
    }

    override func layout() {
        super.layout()

        let bounds = self.bounds
        contentContainerView.frame = NSRect(x: 0, y: 0, width: bounds.width, height: bounds.height)

        if let contentView = contentContainerView.subviews.first {
            contentView.frame = contentContainerView.bounds
            contentView.autoresizingMask = [.width, .height]
        }
    }
}

private final class AdjustmentSpacerView: NSView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
        isHidden = false
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
        isHidden = false
    }
}
