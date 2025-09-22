//
//  ScrollViewController.swift
//  Package
//
//  Created by Ockey on 2025/09/22.
//

import AppKit
import IdentifiedCollections
import SwiftDeclaration

private final class ColumnViewState {
    private let widthConstraint: NSLayoutConstraint

    var width: CGFloat {
        didSet {
            widthConstraint.constant = width
        }
    }

    init(width: CGFloat, widthConstraint: NSLayoutConstraint) {
        self.widthConstraint = widthConstraint
        self.width = width
        widthConstraint.constant = width
    }

    @discardableResult
    func adjustWidth(delta: CGFloat, minimumWidth: CGFloat) -> CGFloat {
        let previousWidth = width
        let newWidth = max(minimumWidth, previousWidth + delta)
        width = newWidth
        return newWidth - previousWidth
    }
}

final class ScrollViewController: NSViewController {
    private final class ColumnContext {
        let containerView: NSView
        let boundaryView: NSView
        let panGesture: NSPanGestureRecognizer
        let addButton: NSButton
        let outlineView: NSOutlineView
        let outlineDataSource: DeclarationOutlineDataSource
        let state: ColumnViewState
        var lastTranslationX: CGFloat = 0
        var dragStartedAtRightEdge = false

        init(
            containerView: NSView,
            boundaryView: NSView,
            panGesture: NSPanGestureRecognizer,
            addButton: NSButton,
            outlineView: NSOutlineView,
            outlineDataSource: DeclarationOutlineDataSource,
            state: ColumnViewState,
        ) {
            self.containerView = containerView
            self.boundaryView = boundaryView
            self.panGesture = panGesture
            self.addButton = addButton
            self.outlineView = outlineView
            self.outlineDataSource = outlineDataSource
            self.state = state
        }
    }

    private final class DeclarationOutlineDataSource: NSObject, NSOutlineViewDataSource, NSOutlineViewDelegate {
        final class Node: NSObject {
            let declaration: AbstractDeclaration
            let children: [Node]
            init(declaration: AbstractDeclaration, children: [Node]) {
                self.declaration = declaration
                self.children = children
                super.init()
            }
        }

        private(set) var rootNodes: [Node] = []

        func update(with declarations: IdentifiedArrayOf<AbstractDeclaration>) {
            rootNodes = declarations.map { decl in
                buildNode(from: decl)
            }
        }

        private func buildNode(from declaration: AbstractDeclaration) -> Node {
            let childrenDecls: [AbstractDeclaration] =
                Array(declaration.variables)
                    + Array(declaration.functions)
                    + Array(declaration.cases)
                    + Array(declaration.nestingStructs)
                    + Array(declaration.nestingClasses)
                    + Array(declaration.nestingEnums)
            let children = childrenDecls.map { buildNode(from: $0) }
            return Node(declaration: declaration, children: children)
        }

        // MARK: NSOutlineViewDataSource

        func outlineView(_: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
            guard let node = item as? Node else {
                return rootNodes.count
            }
            return node.children.count
        }

        func outlineView(_: NSOutlineView, isItemExpandable item: Any) -> Bool {
            guard let node = item as? Node else {
                return false
            }
            return node.children.isEmpty == false
        }

        func outlineView(_: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
            guard let node = item as? Node else {
                return rootNodes[index]
            }
            return node.children[index]
        }

        // MARK: NSOutlineViewDelegate

        func outlineView(_ outlineView: NSOutlineView, viewFor _: NSTableColumn?, item: Any) -> NSView? {
            guard let node = item as? Node else {
                return nil
            }

            let identifier = NSUserInterfaceItemIdentifier("DeclarationCell")
            let cellView: NSTableCellView
            if let reused = outlineView.makeView(withIdentifier: identifier, owner: self) as? NSTableCellView {
                cellView = reused
            } else {
                cellView = NSTableCellView()
                cellView.identifier = identifier

                let textField = NSTextField(labelWithString: "")
                textField.translatesAutoresizingMaskIntoConstraints = false
                cellView.addSubview(textField)
                cellView.textField = textField

                NSLayoutConstraint.activate([
                    textField.leadingAnchor.constraint(equalTo: cellView.leadingAnchor, constant: 4),
                    textField.trailingAnchor.constraint(equalTo: cellView.trailingAnchor, constant: -4),
                    textField.centerYAnchor.constraint(equalTo: cellView.centerYAnchor),
                ])
            }

            cellView.textField?.stringValue = node.declaration.name
            return cellView
        }
    }

    private static let minColumnWidth: CGFloat = 250

    private var scrollView: NSScrollView!
    private var stackView: NSStackView!
    private var rightEdgeSpacerView: NSView!
    private var rightEdgeSpacerConstraint: NSLayoutConstraint!
    private var rightEdgeSpacerWidth: CGFloat = 0

    private var columns: [ColumnContext] = []
    private var gestureToColumn: [ObjectIdentifier: ColumnContext] = [:]
    private var buttonToColumn: [ObjectIdentifier: ColumnContext] = [:]

    private var lastContentOffsetX: CGFloat = 0
    private var isRubberBandingOnRightEdge = false

    override func viewDidLoad() {
        super.viewDidLoad()

        scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = true
        scrollView.borderType = .noBorder
        view.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: 52),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        stackView = NSStackView()
        stackView.orientation = .horizontal
        stackView.spacing = 0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = stackView

        scrollView.contentView.postsBoundsChangedNotifications = true
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(contentViewDidScroll(_:)),
            name: NSView.boundsDidChangeNotification,
            object: scrollView.contentView,
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(scrollViewDidEndLiveScroll(_:)),
            name: NSScrollView.didEndLiveScrollNotification,
            object: scrollView,
        )
        lastContentOffsetX = scrollView.contentView.bounds.origin.x

        let clipView = scrollView.contentView

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: clipView.leadingAnchor),
            stackView.topAnchor.constraint(equalTo: clipView.topAnchor),
            stackView.heightAnchor.constraint(equalTo: clipView.heightAnchor),
        ])

        configureInitialColumns()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc
    private func handleBoundaryPan(_ gesture: NSPanGestureRecognizer) {
        guard let column = gestureToColumn[ObjectIdentifier(gesture)] else {
            return
        }

        let translationX = gesture.translation(in: view).x

        switch gesture.state {
        case .began:
            column.lastTranslationX = translationX
            column.dragStartedAtRightEdge = isScrolledToRightEdge()

        case .changed:
            let delta = translationX - column.lastTranslationX
            column.lastTranslationX = translationX
            guard delta != 0 else {
                return
            }
            column.dragStartedAtRightEdge = isScrolledToRightEdge()
            applyWidths(for: column, delta: delta, shouldLayout: true)

        default:
            column.lastTranslationX = 0
            column.dragStartedAtRightEdge = false
        }
    }

    @objc
    private func handleAddColumnButton(_ sender: NSButton) {
        guard let column = buttonToColumn[ObjectIdentifier(sender)],
              let index = columns.firstIndex(where: { $0 === column }) else {
            return
        }

        removeColumns(after: index)
        setRightEdgeSpacerWidth(0)

        let referenceColor = column.containerView.layer?.backgroundColor
            .flatMap { NSColor(cgColor: $0) } ?? .systemBlue
        let newColumn = createColumn(initialWidth: column.state.width, color: referenceColor)

        insertColumn(newColumn, after: index)
        view.layoutSubtreeIfNeeded()
    }

    @objc
    private func contentViewDidScroll(_: Notification) {
        guard scrollView != nil else {
            return
        }
        let currentOffsetX = scrollView.contentView.bounds.origin.x
        let delta = currentOffsetX - lastContentOffsetX
        lastContentOffsetX = currentOffsetX

        updateRubberBandingState()

        guard delta < 0 else {
            return
        }

        let currentRightEdgeSpacerWidth = rightEdgeSpacerWidth
        guard currentRightEdgeSpacerWidth > 0 else {
            return
        }

        guard isRubberBandingOnRightEdge == false else {
            return
        }

        let shrinkAmount = min(-delta, currentRightEdgeSpacerWidth)
        guard shrinkAmount > 0 else {
            return
        }

        setRightEdgeSpacerWidth(currentRightEdgeSpacerWidth - shrinkAmount)
        view.layoutSubtreeIfNeeded()
    }

    private func applyWidths(for column: ColumnContext, delta: CGFloat, shouldLayout: Bool) {
        let appliedDelta = column.state.adjustWidth(delta: delta, minimumWidth: Self.minColumnWidth)
        guard appliedDelta != 0 else {
            return
        }

        updateRightEdgeSpacerWidth(using: appliedDelta, dragStartedAtRightEdge: column.dragStartedAtRightEdge)

        if shouldLayout {
            view.layoutSubtreeIfNeeded()
        }
    }

    private func updateRightEdgeSpacerWidth(using delta: CGFloat, dragStartedAtRightEdge: Bool) {
        let currentWidth = rightEdgeSpacerWidth
        var newWidth = currentWidth

        if currentWidth > 0, delta > 0 {
            newWidth = max(0, currentWidth - delta)
        } else if dragStartedAtRightEdge, delta < 0 {
            newWidth = max(0, currentWidth - delta)
        }

        setRightEdgeSpacerWidth(newWidth)
    }

    private func setRightEdgeSpacerWidth(_ width: CGFloat) {
        rightEdgeSpacerWidth = width
        rightEdgeSpacerConstraint.constant = width
    }

    private func configureInitialColumns() {
        columns = []

        rightEdgeSpacerView = NSView()
        rightEdgeSpacerView.translatesAutoresizingMaskIntoConstraints = false
        rightEdgeSpacerView.wantsLayer = true
        rightEdgeSpacerView.layer?.backgroundColor = NSColor.systemGreen.cgColor
        stackView.addArrangedSubview(rightEdgeSpacerView)

        rightEdgeSpacerConstraint = rightEdgeSpacerView.widthAnchor.constraint(equalToConstant: rightEdgeSpacerWidth)
        rightEdgeSpacerConstraint.isActive = true
    }

    func resetToSingleColumnKeepingFirstWidth(defaultWidth: CGFloat = 500, color: NSColor = .systemBlue) {
        let targetWidth = columns.first?.state.width ?? defaultWidth

        removeAllColumns()
        setRightEdgeSpacerWidth(0)

        let newColumn = createColumn(initialWidth: targetWidth, color: color)
        registerColumn(newColumn)
        columns = [newColumn]

        if let rightEdgeSpacerIndex = stackView.arrangedSubviews.firstIndex(of: rightEdgeSpacerView) {
            stackView.insertArrangedSubview(newColumn.containerView, at: rightEdgeSpacerIndex)
            stackView.insertArrangedSubview(newColumn.boundaryView, at: rightEdgeSpacerIndex + 1)
        } else {
            stackView.addArrangedSubview(newColumn.containerView)
            stackView.addArrangedSubview(newColumn.boundaryView)
        }

        view.layoutSubtreeIfNeeded()
    }

    func resetToSingleColumnDisplaying(
        declarations: IdentifiedArrayOf<AbstractDeclaration>,
        defaultWidth: CGFloat = 500,
        color: NSColor = .systemBlue,
    ) {
        let targetWidth = columns.first?.state.width ?? defaultWidth

        removeAllColumns()
        setRightEdgeSpacerWidth(0)

        let newColumn = createColumn(initialWidth: targetWidth, color: color)
        newColumn.outlineDataSource.update(with: declarations)
        newColumn.outlineView.reloadData()

        registerColumn(newColumn)
        columns = [newColumn]

        if let rightEdgeSpacerIndex = stackView.arrangedSubviews.firstIndex(of: rightEdgeSpacerView) {
            stackView.insertArrangedSubview(newColumn.containerView, at: rightEdgeSpacerIndex)
            stackView.insertArrangedSubview(newColumn.boundaryView, at: rightEdgeSpacerIndex + 1)
        } else {
            stackView.addArrangedSubview(newColumn.containerView)
            stackView.addArrangedSubview(newColumn.boundaryView)
        }

        view.layoutSubtreeIfNeeded()
    }

    private func createColumn(initialWidth: CGFloat, color: NSColor) -> ColumnContext {
        let containerView = NSView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.wantsLayer = true
        containerView.layer?.backgroundColor = color.cgColor

        let addButton: NSButton
        if let addImage = NSImage(named: NSImage.addTemplateName) {
            addButton = NSButton(image: addImage, target: self, action: #selector(handleAddColumnButton(_:)))
            addButton.isBordered = false
        } else {
            addButton = NSButton(title: "+", target: self, action: #selector(handleAddColumnButton(_:)))
            addButton.bezelStyle = .inline
        }
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.imagePosition = .imageOnly
        addButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        addButton.setContentCompressionResistancePriority(.required, for: .vertical)
        containerView.addSubview(addButton)
        NSLayoutConstraint.activate([
            addButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            addButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
        ])

        let scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false
        containerView.addSubview(scrollView)

        let outlineView = NSOutlineView()
        outlineView.headerView = nil
        outlineView.usesAlternatingRowBackgroundColors = false
        outlineView.backgroundColor = .clear
        outlineView.allowsMultipleSelection = false
        outlineView.allowsEmptySelection = true
        outlineView.rowSizeStyle = .default

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("DeclarationColumn"))
        column.title = "Declarations"
        column.minWidth = 160
        column.resizingMask = .autoresizingMask
        outlineView.addTableColumn(column)
        outlineView.outlineTableColumn = column

        let ds = DeclarationOutlineDataSource()
        outlineView.dataSource = ds
        outlineView.delegate = ds

        scrollView.documentView = outlineView

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: containerView.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ])

        let widthConstraint = containerView.widthAnchor.constraint(equalToConstant: initialWidth)
        widthConstraint.isActive = true
        let state = ColumnViewState(width: initialWidth, widthConstraint: widthConstraint)

        let boundaryView = NSView()
        boundaryView.translatesAutoresizingMaskIntoConstraints = false
        boundaryView.wantsLayer = true
        boundaryView.layer?.backgroundColor = NSColor.white.cgColor
        let boundaryWidthConstraint = boundaryView.widthAnchor.constraint(equalToConstant: 10)
        boundaryWidthConstraint.isActive = true

        let panGesture = NSPanGestureRecognizer(target: self, action: #selector(handleBoundaryPan(_:)))
        boundaryView.addGestureRecognizer(panGesture)

        return ColumnContext(
            containerView: containerView,
            boundaryView: boundaryView,
            panGesture: panGesture,
            addButton: addButton,
            outlineView: outlineView,
            outlineDataSource: ds,
            state: state,
        )
    }

    private func insertColumn(_ column: ColumnContext, after index: Int) {
        registerColumn(column)
        columns.insert(column, at: index + 1)

        guard let boundaryIndex = stackView.arrangedSubviews.firstIndex(of: columns[index].boundaryView) else {
            return
        }

        let columnInsertionIndex = boundaryIndex + 1
        stackView.insertArrangedSubview(column.containerView, at: columnInsertionIndex)
        stackView.insertArrangedSubview(column.boundaryView, at: columnInsertionIndex + 1)
    }

    private func removeColumns(after index: Int) {
        guard index + 1 < columns.count else {
            return
        }

        for removalIndex in stride(from: columns.count - 1, through: index + 1, by: -1) {
            let column = columns.remove(at: removalIndex)
            deregisterColumn(column)
            stackView.removeArrangedSubview(column.boundaryView)
            column.boundaryView.removeFromSuperview()
            stackView.removeArrangedSubview(column.containerView)
            column.containerView.removeFromSuperview()
        }
    }

    private func removeAllColumns() {
        guard columns.isEmpty == false else {
            return
        }

        for removalIndex in stride(from: columns.count - 1, through: 0, by: -1) {
            let column = columns.remove(at: removalIndex)
            deregisterColumn(column)
            stackView.removeArrangedSubview(column.boundaryView)
            column.boundaryView.removeFromSuperview()
            stackView.removeArrangedSubview(column.containerView)
            column.containerView.removeFromSuperview()
        }
    }

    private func registerColumn(_ column: ColumnContext) {
        gestureToColumn[ObjectIdentifier(column.panGesture)] = column
        buttonToColumn[ObjectIdentifier(column.addButton)] = column
    }

    private func deregisterColumn(_ column: ColumnContext) {
        gestureToColumn.removeValue(forKey: ObjectIdentifier(column.panGesture))
        buttonToColumn.removeValue(forKey: ObjectIdentifier(column.addButton))
    }

    private func isScrolledToRightEdge() -> Bool {
        guard let documentView = scrollView.documentView else {
            return false
        }

        let visibleRect = scrollView.documentVisibleRect
        let documentWidth = documentView.bounds.width

        if documentWidth <= visibleRect.width {
            return false
        }

        return visibleRect.maxX == documentWidth
    }

    private func updateRubberBandingState() {
        guard let documentView = scrollView.documentView else {
            isRubberBandingOnRightEdge = false
            return
        }

        let visibleRect = scrollView.documentVisibleRect
        let documentWidth = documentView.bounds.width

        if visibleRect.maxX > documentWidth {
            isRubberBandingOnRightEdge = true
        } else if visibleRect.maxX <= documentWidth - 1 {
            isRubberBandingOnRightEdge = false
        }
    }

    @objc
    private func scrollViewDidEndLiveScroll(_: Notification) {
        updateRubberBandingState()
    }
}
