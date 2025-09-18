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
    var scrollView: NSScrollView!
    var resizableView: ResizableColumnsView!

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

        columns = [ColumnState(roots: [DeclarationCellState.dummy], width: 450)]

        let initialController = DeclarationTreeViewController()
        initialController.view.frame = NSRect(x: 0, y: 0, width: 600, height: 800)
        initialController.configure(rootCells: [DeclarationCellState.dummy])
//        initialController.onClidked = { [weak self, weak initialController] _ in
//
//        }
//        initialController.onSelectionChanged = { [weak self, weak initialController] _ in
//
//        }

        treeControllers = [initialController]

        let columns = [ResizableColumnsView.Column(contentView: initialController.view, width: columns.first?.width ?? 450)]
        resizableView = ResizableColumnsView(columns: columns)
        // The height syncs to the scroll view’s visible height at layout time.
        resizableView.frame = NSRect(x: 0, y: 0, width: 1000, height: 1)
        scrollView.documentView = resizableView

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: Layout

    override func viewDidLayout() {
        super.viewDidLayout()
        syncDocumentHeightToVisible()
        setInitialOffsetIfNeeded()
    }

    private func syncDocumentHeightToVisible() {
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
              let documentView = scrollView.documentView else {
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

    private func appendColumn(from controller: DeclarationTreeViewController, with cell: DeclarationCellState) {

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
