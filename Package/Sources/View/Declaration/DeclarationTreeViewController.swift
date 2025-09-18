//
//  DeclarationTreeViewController.swift
//  Package
//
//  Created by Ockey on 2025/09/16.
//

import AppKit
import Location
import SwiftDeclaration

final class DeclarationTreeViewController: NSViewController {
    private var rootCells: [DeclarationCellState] = []
    private var scrollView: NSScrollView!
    private var outlineView: NSOutlineView!

    var onClidked: ((DeclarationCellState) -> Void)?
    var onSelectionChanged: ((DeclarationCellState) -> Void)?

    private static let nameColumnIdentifier = NSUserInterfaceItemIdentifier("NameColumn")
    private static let nameCellIdentifier = NSUserInterfaceItemIdentifier("NameCell")

    override func viewDidLoad() {
        super.viewDidLoad()
        setupOutlineView()
        outlineView.reloadData()
    }

    private func setupOutlineView() {
        scrollView = VerticalOnlyScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = false
        scrollView.scrollerStyle = .legacy

        outlineView = NSOutlineView()
        outlineView.dataSource = self
        outlineView.delegate = self
        outlineView.target = self
        outlineView.action = #selector(onRowClicked(_:))
        outlineView.headerView = nil
        outlineView.usesAlternatingRowBackgroundColors = false
        outlineView.allowsMultipleSelection = false
        outlineView.allowsColumnSelection = false
        outlineView.allowsEmptySelection = true
        outlineView.floatsGroupRows = false
        outlineView.rowSizeStyle = .default

        let nameColumn = NSTableColumn(identifier: Self.nameColumnIdentifier)
        nameColumn.minWidth = 100
        nameColumn.width = 300
        nameColumn.resizingMask = .autoresizingMask
        outlineView.addTableColumn(nameColumn)
        outlineView.outlineTableColumn = nameColumn

        outlineView.columnAutoresizingStyle = .firstColumnOnlyAutoresizingStyle

        scrollView.documentView = outlineView

        view.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    func configure(rootCells: [DeclarationCellState]) {
        self.rootCells = rootCells
        if isViewLoaded {
            outlineView.reloadData()
        }
    }

    @objc private func onRowClicked(_ sender: Any?) {}
}

extension DeclarationTreeViewController: NSOutlineViewDataSource {
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        guard let item else {
            return rootCells.count
        }
        guard let cellState = item as? DeclarationCellState else {
            return 0
        }

        return cellState.children.count
    }

    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        guard let item else {
            if (0..<rootCells.count).contains(index) {
                return rootCells[index]
            } else {
                return DeclarationCellState(
                    declaration: AbstractDeclaration(
                        id: UUID(),
                        name: "",
                        kind: .struct,
                        sourceLocationRange: Location(fullPath: "", line: 0, column: 0)...Location(fullPath: "", line: 0, column: 1)
                    )
                )
            }
        }

        guard let cellState = item as? DeclarationCellState else {
            return DeclarationCellState(
                declaration: AbstractDeclaration(
                    id: UUID(),
                    name: "",
                    kind: .struct,
                    sourceLocationRange: Location(fullPath: "", line: 0, column: 0)...Location(fullPath: "", line: 0, column: 1)
                )
            )
        }

        guard (0..<cellState.children.count).contains(index) else {
            return DeclarationCellState(
                declaration: AbstractDeclaration(
                    id: UUID(),
                    name: "",
                    kind: .struct,
                    sourceLocationRange: Location(fullPath: "", line: 0, column: 0)...Location(fullPath: "", line: 0, column: 1)
                )
            )
        }

        return DeclarationCellState(declaration: cellState.children[index])
    }

    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        guard let cellState = item as? DeclarationCellState else {
            return false
        }

        return cellState.hasChildren
    }
}

extension DeclarationTreeViewController: NSOutlineViewDelegate {
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let cellState = item as? DeclarationCellState else {
            return nil
        }

        if tableColumn?.identifier == Self.nameColumnIdentifier {
            var view = outlineView.makeView(withIdentifier: Self.nameCellIdentifier, owner: self) as? NameCell
            if view == nil {
                view = NameCell()
                view?.identifier = Self.nameCellIdentifier
            }
            view?.configure(with: cellState)
            return view
        }

        return nil
    }
}
