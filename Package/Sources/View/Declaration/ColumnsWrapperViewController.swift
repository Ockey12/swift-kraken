//
//  ColumnsWrapperViewController.swift
//  Package
//
//  Created by Ockey on 2025/09/18.
//

import AppKit
import SwiftDeclaration

final class ColumnsWrapperViewController: NSViewController {
    struct ColumnState {
        var roots: [DeclarationCellState]
        var width: CGFloat
    }

    private var columns: [ColumnState] = []
    private var treeControllers: [DeclarationTreeViewController] = []
    private var didSetInitialContentOffset = false
    private let emptyDocumentView = NSView(frame: NSRect(x: 0, y: 0, width: 1, height: 1))
    var scrollView: NSScrollView!
    private var resizableView: ResizableColumnsView?

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }

    private func setup() {
        scrollView = NSScrollView()
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalRuler = true
        scrollView.autohidesScrollers = false
        scrollView.scrollerStyle = .legacy
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        scrollView.documentView = emptyDocumentView

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    // MARK: Layout

    override func viewDidLayout() {
        super.viewDidLayout()
        syncDocumentHeightToVisible()
        setInitialOffsetIfNeeded()
    }

    private func syncDocumentHeightToVisible() {
        guard let resizableView else {
            return
        }

        let visibleHeight = max(1, scrollView.contentSize.height)
        if resizableView.frame.size.height != visibleHeight {
            var frame = resizableView.frame
            frame.size.height = visibleHeight
            resizableView.frame = frame
            resizableView.needsLayout = true
            resizableView.layoutSubtreeIfNeeded()
            resizableView.needsDisplay = true
        }
    }

    private func setInitialOffsetIfNeeded() {
        guard !didSetInitialContentOffset,
              let documentView = scrollView.documentView,
              documentView !== emptyDocumentView else {
            return
        }

        let contentSize = scrollView.contentSize
        let documentSize = documentView.bounds.size
        let targetY = max(0, documentSize.height - contentSize.height)
        scrollView.contentView.scroll(to: NSPoint(x: 0, y: targetY))
        scrollView.reflectScrolledClipView(scrollView.contentView)
        didSetInitialContentOffset = true
    }

    // MARK: Columns management

    private func appendColumn(from _: DeclarationTreeViewController, with _: DeclarationCellState) {}

    func display(declarations: [AbstractDeclaration]) {
        if !isViewLoaded {
            _ = view
        }

        guard !declarations.isEmpty else {
            clearRootDeclarations()
            return
        }

        let rootCells = declarations.map(DeclarationCellState.init)

        if columns.isEmpty || treeControllers.isEmpty || resizableView == nil {
            createRootColumn(with: rootCells)
        } else {
            columns[0].roots = rootCells
            treeControllers[0].configure(rootCells: rootCells)
            refreshLayout()
        }

        didSetInitialContentOffset = false
    }

    func clearRootDeclarations() {
        if !isViewLoaded {
            _ = view
        }

        columns.removeAll()
        treeControllers.removeAll()
        resizableView?.removeFromSuperview()
        resizableView = nil
        scrollView.documentView = emptyDocumentView
        didSetInitialContentOffset = false
    }

    private func createRootColumn(with rootCells: [DeclarationCellState]) {
        let controller = DeclarationTreeViewController()
        controller.view.frame = NSRect(x: 0, y: 0, width: 600, height: 800)
        controller.configure(rootCells: rootCells)
        treeControllers = [controller]
        columns = [ColumnState(roots: rootCells, width: 450)]

        let column = ResizableColumnsView.Column(contentView: controller.view, width: columns.first?.width ?? 450)
        let resizableView = ResizableColumnsView(columns: [column])
        let initialWidth = max(columns.first?.width ?? 450, scrollView.bounds.width)
        let initialHeight = max(1, scrollView.bounds.height)
        resizableView.frame = NSRect(x: 0, y: 0, width: initialWidth, height: initialHeight)
        scrollView.documentView = resizableView
        self.resizableView = resizableView
        resizableView.updateTopClipHeight(scrollView.contentInsets.top)
        refreshLayout()
    }

    private func refreshLayout() {
        scrollView?.layoutSubtreeIfNeeded()
        resizableView?.needsLayout = true
        resizableView?.layoutSubtreeIfNeeded()
        syncDocumentHeightToVisible()
        treeControllers.first?.view.needsLayout = true
        treeControllers.first?.view.layoutSubtreeIfNeeded()
        treeControllers.first?.view.needsDisplay = true
        resizableView?.needsDisplay = true
    }

    // MARK: Array state

    private func indexOfController(_ targetController: DeclarationTreeViewController) -> Int? {
        for (index, controller) in treeControllers.enumerated() {
            if controller === targetController {
                return index
            }
        }
        return nil
    }
}
