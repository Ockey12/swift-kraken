//
//  ScrollViewController.swift
//  Package
//
//  Created by Ockey on 2025/09/22.
//

import AppKit
import Foundation
import IdentifiedCollections
import SwiftDeclaration

private final class VerticalOnlyScrollView: NSScrollView {
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

private final class VerticalDividerView: NSView {
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
        enum DependencyFilter: Int, CaseIterable { case all = 0, referrers = 1, referenced = 2 }
        let containerView: NSView
        let headerView: NSView
        let titleLabel: NSTextField
        let filterControl: NSSegmentedControl?
        let boundaryView: NSView
        let outlineView: NSOutlineView
        let outlineDataSource: DeclarationOutlineDataSource
        let state: ColumnViewState
        var dragStartedAtRightEdge = false
        var dragStartLocationX: CGFloat?
        var dragInitialWidth: CGFloat = 0

        // Context for dependency columns
        var titleDeclaration: AbstractDeclaration?
        var currentFilter: DependencyFilter = .all
        var expandedIDsByFilter: [DependencyFilter: Set<UUID>] = [:]
        var dependenciesAll: IdentifiedArrayOf<AbstractDeclaration> = []
        var dependenciesReferrers: IdentifiedArrayOf<AbstractDeclaration> = []
        var dependenciesReferenced: IdentifiedArrayOf<AbstractDeclaration> = []

        init(
            containerView: NSView,
            headerView: NSView,
            titleLabel: NSTextField,
            filterControl: NSSegmentedControl?,
            boundaryView: NSView,
            outlineView: NSOutlineView,
            outlineDataSource: DeclarationOutlineDataSource,
            state: ColumnViewState,
        ) {
            self.containerView = containerView
            self.headerView = headerView
            self.titleLabel = titleLabel
            self.filterControl = filterControl
            self.boundaryView = boundaryView
            self.outlineView = outlineView
            self.outlineDataSource = outlineDataSource
            self.state = state
        }
    }

    @MainActor
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
        weak var columnContext: ColumnContext?
        var onArrowTapped: ((AbstractDeclaration, ColumnContext) -> Void)?
        private var buttonToNode: [ObjectIdentifier: Node] = [:]
        private var nodeCacheByID: [UUID: Node] = [:]

        func update(with declarations: IdentifiedArrayOf<AbstractDeclaration>) {
            rootNodes = declarations.map { decl in
                buildNode(from: decl)
            }
            rebuildNodeCache()
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

        private func rebuildNodeCache() {
            nodeCacheByID.removeAll(keepingCapacity: true)
            func walk(_ node: Node) {
                nodeCacheByID[node.declaration.id] = node
                node.children.forEach(walk)
            }
            rootNodes.forEach(walk)
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

        func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
            guard let node = item as? Node else {
                return nil
            }

            guard let tableColumn else {
                return nil
            }

            if tableColumn.identifier.rawValue == "NameColumn" {
                let identifier = NSUserInterfaceItemIdentifier("NameCell")
                let cellView: NSTableCellView
                if let reused = outlineView.makeView(withIdentifier: identifier, owner: self) as? NSTableCellView {
                    cellView = reused
                } else {
                    cellView = NSTableCellView()
                    cellView.identifier = identifier

                    let textField = NSTextField(labelWithString: "")
                    textField.translatesAutoresizingMaskIntoConstraints = false
                    textField.lineBreakMode = .byTruncatingTail
                    textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
                    cellView.addSubview(textField)
                    cellView.textField = textField

                    NSLayoutConstraint.activate([
                        textField.leadingAnchor.constraint(equalTo: cellView.leadingAnchor, constant: 4),
                        textField.trailingAnchor.constraint(equalTo: cellView.trailingAnchor, constant: -4),
                        textField.centerYAnchor.constraint(equalTo: cellView.centerYAnchor),
                    ])
                }

                cellView.textField?.stringValue = node.declaration.joinedHierarchicalName
                return cellView
            } else if tableColumn.identifier.rawValue == "ActionColumn" {
                let identifier = NSUserInterfaceItemIdentifier("ActionCell")
                let cellView: NSTableCellView
                let arrowButton: NSButton
                if let reused = outlineView.makeView(withIdentifier: identifier, owner: self) as? NSTableCellView,
                   let reusedButton = reused.subviews.compactMap({ $0 as? NSButton }).first {
                    cellView = reused
                    arrowButton = reusedButton
                } else {
                    cellView = NSTableCellView()
                    cellView.identifier = identifier

                    if let img = NSImage(systemSymbolName: "arrow.right.circle.fill", accessibilityDescription: "Open Dependencies") {
                        arrowButton = NSButton(image: img, target: self, action: #selector(arrowButtonTapped(_:)))
                        arrowButton.isBordered = false
                    } else {
                        arrowButton = NSButton(title: "→", target: self, action: #selector(arrowButtonTapped(_:)))
                        arrowButton.bezelStyle = .inline
                    }
                    arrowButton.translatesAutoresizingMaskIntoConstraints = false
                    arrowButton.identifier = NSUserInterfaceItemIdentifier("RightArrowButton")
                    arrowButton.setContentCompressionResistancePriority(.required, for: .horizontal)
                    arrowButton.setContentCompressionResistancePriority(.required, for: .vertical)
                    cellView.addSubview(arrowButton)

                    NSLayoutConstraint.activate([
                        arrowButton.trailingAnchor.constraint(equalTo: cellView.trailingAnchor),
                        arrowButton.centerYAnchor.constraint(equalTo: cellView.centerYAnchor),
                        arrowButton.widthAnchor.constraint(equalToConstant: 24),
                        arrowButton.heightAnchor.constraint(equalToConstant: 24),
                    ])
                }

                buttonToNode[ObjectIdentifier(arrowButton)] = node
                arrowButton.target = self
                arrowButton.action = #selector(arrowButtonTapped(_:))
                return cellView
            }

            return nil
        }

        @objc
        private func arrowButtonTapped(_ sender: NSButton) {
            guard let node = buttonToNode[ObjectIdentifier(sender)],
                  let context = columnContext else {
                return
            }
            onArrowTapped?(node.declaration, context)
        }

        // MARK: Expansion state helpers

        func collectExpandedIDs(in outlineView: NSOutlineView) -> Set<UUID> {
            var expanded: Set<UUID> = []

            func walk(_ node: Node) {
                if outlineView.isItemExpanded(node) {
                    expanded.insert(node.declaration.id)
                    node.children.forEach(walk)
                }
            }

            rootNodes.forEach(walk)
            return expanded
        }

        func restoreExpandedState(ids: Set<UUID>, in outlineView: NSOutlineView) {
            func shouldExpand(_ node: Node) -> Bool {
                if ids.contains(node.declaration.id) {
                    return true
                }
                for child in node.children where shouldExpand(child) {
                    return true
                }
                return false
            }

            func expandRecursively(_ node: Node) {
                if shouldExpand(node) {
                    outlineView.expandItem(node)
                    node.children.forEach(expandRecursively)
                }
            }

            rootNodes.forEach(expandRecursively)
        }
    }

    private static let minColumnWidth: CGFloat = 260

    private var scrollView: NSScrollView!
    private var stackView: NSStackView!
    private var rightEdgeSpacerView: NSView!
    private var rightEdgeSpacerConstraint: NSLayoutConstraint!
    private var rightEdgeSpacerWidth: CGFloat = 0

    private var columns: [ColumnContext] = []
    private var segmentedToColumn: [ObjectIdentifier: ColumnContext] = [:]
    private var columnByBoundaryID: [ObjectIdentifier: ColumnContext] = [:]

    private var rootDirectory: RootDirectory?

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

    // no-op: add button removed

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
        stackView.addArrangedSubview(rightEdgeSpacerView)

        rightEdgeSpacerConstraint = rightEdgeSpacerView.widthAnchor.constraint(equalToConstant: rightEdgeSpacerWidth)
        rightEdgeSpacerConstraint.isActive = true
    }

    func resetToSingleColumnDisplaying(
        declarations: IdentifiedArrayOf<AbstractDeclaration>,
        headerTitle: String,
        defaultWidth: CGFloat = 320,
    ) {
        let targetWidth = columns.first?.state.width ?? defaultWidth

        removeAllColumns()
        setRightEdgeSpacerWidth(0)

        let newColumn = createColumn(initialWidth: targetWidth, includeFilter: false)
        // Show the full file path in the first column header (truncate head)
        newColumn.titleLabel.stringValue = headerTitle
        newColumn.titleLabel.lineBreakMode = .byTruncatingHead
        // The first column does not include a segmented control (includeFilter: false)
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

    func updateRootDirectory(_ newRootDirectory: RootDirectory) {
        rootDirectory = newRootDirectory
    }

    private func createColumn(initialWidth: CGFloat, includeFilter: Bool) -> ColumnContext {
        let containerView = NSView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.wantsLayer = true

        // Header (title) view at top.
        let headerView = NSView()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.wantsLayer = false
        containerView.addSubview(headerView)

        let titleLabel = NSTextField(labelWithString: "")
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.font = .systemFont(ofSize: NSFont.systemFontSize, weight: .semibold)
        titleLabel.alignment = .center
        headerView.addSubview(titleLabel)

        // Segmented control for dependency filter (only when includeFilter == true)
        var filterControl: NSSegmentedControl?
        if includeFilter {
            let control = NSSegmentedControl(labels: ["All", "Referrers", "Referenced"], trackingMode: .selectOne, target: self, action: #selector(filterSegmentChanged(_:)))
            control.translatesAutoresizingMaskIntoConstraints = false
            control.selectedSegment = 0
            headerView.addSubview(control)
            // Set per-segment width to text width + 20pt padding on both sides
            let font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
            for i in 0 ..< control.segmentCount {
                let title = control.label(forSegment: i) ?? ""
                let width = (title as NSString).size(withAttributes: [.font: font]).width
                control.setWidth(ceil(width + 32), forSegment: i)
            }
            filterControl = control
        }

        let scrollView = VerticalOnlyScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false
        scrollView.horizontalScrollElasticity = .none
        containerView.addSubview(scrollView)

        let outlineView = NSOutlineView()
        outlineView.headerView = nil
        outlineView.columnAutoresizingStyle = .firstColumnOnlyAutoresizingStyle
        outlineView.usesAlternatingRowBackgroundColors = false
        outlineView.backgroundColor = .clear
        outlineView.allowsMultipleSelection = false
        outlineView.allowsEmptySelection = true
        outlineView.rowSizeStyle = .default

        let nameColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("NameColumn"))
        nameColumn.title = ""
        nameColumn.minWidth = 160
        nameColumn.resizingMask = .autoresizingMask

        let actionColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("ActionColumn"))
        actionColumn.title = ""
        actionColumn.minWidth = 24
        actionColumn.maxWidth = 24
        actionColumn.resizingMask = []

        outlineView.addTableColumn(nameColumn)
        outlineView.addTableColumn(actionColumn)
        outlineView.outlineTableColumn = nameColumn

        let ds = DeclarationOutlineDataSource()
        outlineView.dataSource = ds
        outlineView.delegate = ds

        // Inject callback to open dependencies column when arrow tapped
        ds.onArrowTapped = { [weak self] declaration, context in
            self?.openDependencies(of: declaration, from: context)
        }

        scrollView.documentView = outlineView

        NSLayoutConstraint.activate([
            // Header constraints
            headerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            headerView.topAnchor.constraint(equalTo: containerView.topAnchor),

            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -8),
            titleLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 8),

            // ScrollView constraints
            scrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            scrollView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ])

        if filterControl == nil {
            NSLayoutConstraint.activate([
                titleLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),
            ])
        } else {
            NSLayoutConstraint.activate([
                filterControl!.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
                filterControl!.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
                filterControl!.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -4),
            ])
        }

        let widthConstraint = containerView.widthAnchor.constraint(equalToConstant: initialWidth)
        widthConstraint.isActive = true
        let state = ColumnViewState(width: initialWidth, widthConstraint: widthConstraint)

        let boundaryView = VerticalDividerView()

        boundaryView.onMouseDown = { [weak self] startLocationX in
            guard let self else {
                return
            }
            guard let column = columnContext(for: boundaryView) else {
                return
            }
            column.dragStartLocationX = startLocationX
            column.dragInitialWidth = column.state.width
            column.dragStartedAtRightEdge = isScrolledToRightEdge()
        }

        boundaryView.onDragged = { [weak self] currentLocationX in
            guard let self else {
                return
            }
            guard let column = columnContext(for: boundaryView) else {
                return
            }
            guard let startX = column.dragStartLocationX else {
                return
            }

            let delta = currentLocationX - startX
            let desiredWidth = column.dragInitialWidth + delta
            let widthDelta = desiredWidth - column.state.width
            guard widthDelta != 0 else {
                return
            }

            column.dragStartedAtRightEdge = isScrolledToRightEdge()
            applyWidths(for: column, delta: widthDelta, shouldLayout: true)
        }

        boundaryView.onMouseUp = { [weak self] in
            guard let self else {
                return
            }
            guard let column = columnContext(for: boundaryView) else {
                return
            }
            column.dragStartLocationX = nil
            column.dragInitialWidth = 0
            column.dragStartedAtRightEdge = false
        }

        let context = ColumnContext(
            containerView: containerView,
            headerView: headerView,
            titleLabel: titleLabel,
            filterControl: filterControl,
            boundaryView: boundaryView,
            outlineView: outlineView,
            outlineDataSource: ds,
            state: state,
        )

        // Link datasource back to column context for callbacks
        ds.columnContext = context

        // Wire segmented control to this column context (when exists)
        if let filterControl {
            filterControl.target = self
            filterControl.action = #selector(filterSegmentChanged(_:))
            segmentedToColumn[ObjectIdentifier(filterControl)] = context
        }

        return context
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

        // After adding a new column, scroll to the right edge with animation
        scrollToRightEdge()
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

        columnByBoundaryID.removeAll(keepingCapacity: true)
    }

    private func registerColumn(_ column: ColumnContext) {
        column.outlineDataSource.columnContext = column
        columnByBoundaryID[ObjectIdentifier(column.boundaryView)] = column
    }

    private func deregisterColumn(_ column: ColumnContext) {
        columnByBoundaryID.removeValue(forKey: ObjectIdentifier(column.boundaryView))
        if let filterControl = column.filterControl {
            segmentedToColumn.removeValue(forKey: ObjectIdentifier(filterControl))
        }
    }

    private func columnContext(for boundaryView: NSView) -> ColumnContext? {
        columnByBoundaryID[ObjectIdentifier(boundaryView)]
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

    private func openDependencies(of declaration: AbstractDeclaration, from column: ColumnContext) {
        guard let rootDirectory else {
            return
        }

        var setAll: Set<AbstractDeclaration> = []
        var setReferrers: Set<AbstractDeclaration> = []
        var setReferenced: Set<AbstractDeclaration> = []
        for usr in declaration.definitionUSRs {
            let referrers = rootDirectory.getReferrers(referencedUSR: usr)
            let referenced = rootDirectory.getReferenced(referrerUSR: usr)
            setReferrers.formUnion(referrers)
            setReferenced.formUnion(referenced)
            setAll.formUnion(referrers)
            setAll.formUnion(referenced)
        }
        // Exclude the declaration itself
        setAll.remove(declaration)
        setReferrers.remove(declaration)
        setReferenced.remove(declaration)

        guard let index = columns.firstIndex(where: { $0 === column }) else {
            return
        }

        removeColumns(after: index)
        setRightEdgeSpacerWidth(0)

        let newColumn = createColumn(initialWidth: column.state.width, includeFilter: true)
        // Show header title and enable filter
        newColumn.titleLabel.stringValue = declaration.joinedHierarchicalName
        // Dependency columns include a segmented control (includeFilter: true)
        newColumn.titleDeclaration = declaration

        // Store dependency sets for filtering
        newColumn.dependenciesAll = IdentifiedArray(uniqueElements: Array(setAll))
        newColumn.dependenciesReferrers = IdentifiedArray(uniqueElements: Array(setReferrers))
        newColumn.dependenciesReferenced = IdentifiedArray(uniqueElements: Array(setReferenced))
        newColumn.currentFilter = .all
        newColumn.filterControl?.selectedSegment = ColumnContext.DependencyFilter.all.rawValue

        applyFilter(for: newColumn)

        insertColumn(newColumn, after: index)
        view.layoutSubtreeIfNeeded()
    }

    @objc
    private func filterSegmentChanged(_ sender: NSSegmentedControl) {
        guard let column = segmentedToColumn[ObjectIdentifier(sender)],
              let selected = ColumnContext.DependencyFilter(rawValue: sender.selectedSegment) else {
            return
        }

        // Save expansion state for previous filter
        let prevFilter = column.currentFilter
        let expanded = column.outlineDataSource.collectExpandedIDs(in: column.outlineView)
        column.expandedIDsByFilter[prevFilter] = expanded

        // Apply new filter
        column.currentFilter = selected
        applyFilter(for: column)
    }

    private func applyFilter(for column: ColumnContext) {
        let declarations: IdentifiedArrayOf<AbstractDeclaration> =
            switch column.currentFilter {
            case .all:
                column.dependenciesAll
            case .referrers:
                column.dependenciesReferrers
            case .referenced:
                column.dependenciesReferenced
            }

        column.outlineDataSource.update(with: declarations)
        column.outlineView.reloadData()

        // Restore expansion state if it exists
        if let ids = column.expandedIDsByFilter[column.currentFilter] {
            column.outlineDataSource.restoreExpandedState(ids: ids, in: column.outlineView)
        }
    }

    // Scroll to the right edge with animation
    private func scrollToRightEdge(animated: Bool = true, duration: TimeInterval = 0.25) {
        guard let documentView = scrollView?.documentView else {
            return
        }

        // Ensure layout is up to date to get the correct width
        view.layoutSubtreeIfNeeded()

        let clipView = scrollView.contentView
        let visibleRect = scrollView.documentVisibleRect
        let documentWidth = documentView.bounds.width
        let currentOrigin = clipView.bounds.origin
        let targetX = max(0, documentWidth - visibleRect.width)
        let targetOrigin = NSPoint(x: targetX, y: currentOrigin.y)

        guard abs(currentOrigin.x - targetX) > 0.5 else {
            return
        }

        if animated {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = duration
                clipView.animator().setBoundsOrigin(targetOrigin)
                scrollView.reflectScrolledClipView(clipView)
            }
        } else {
            clipView.setBoundsOrigin(targetOrigin)
            scrollView.reflectScrolledClipView(clipView)
        }
    }
}
