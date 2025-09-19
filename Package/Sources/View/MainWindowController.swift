//
//  MainWindowController.swift
//  Package
//
//  Created by Ockey on 2025/09/19.
//

import AppKit
import SwiftDeclaration

final class MainWindowController: NSWindowController, NSToolbarDelegate {
    private lazy var appViewController = AppViewController(rootDirectory: .dummy)

    override func windowDidLoad() {
        super.windowDidLoad()
        guard let w = window else {
            return
        }

        if w.contentViewController == nil {
            w.contentViewController = appViewController
        }

        // Merge title bar and toolbar
        w.titleVisibility = .hidden
        w.titlebarAppearsTransparent = true
        w.styleMask.insert(.fullSizeContentView)
        if #available(macOS 11.0, *) {
            w.toolbarStyle = .unifiedCompact
        }

        // Toolbar (same row as the window controls)
        let tb = NSToolbar(identifier: .mainToolbar)
        tb.delegate = self
        tb.displayMode = .iconOnly
        tb.allowsUserCustomization = true
        w.toolbar = tb

        // Optional buttons that should stay on the right side
        let acc = NSTitlebarAccessoryViewController()
        acc.layoutAttribute = .right
        let runButton = NSButton(title: "Run", target: self, action: #selector(run))
        runButton.bezelStyle = .toolbar
        acc.view = runButton
        w.addTitlebarAccessoryViewController(acc)

        // Without setting constraints, the content ends up underneath the toolbar.
        if let guide = w.contentLayoutGuide as? NSLayoutGuide, let contentView = w.contentView {
            contentView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                contentView.topAnchor.constraint(equalTo: guide.topAnchor),
                contentView.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
                contentView.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
                contentView.bottomAnchor.constraint(equalTo: guide.bottomAnchor),
            ])
        }
    }

    // MARK: Actions (bridging into the view controller)

    @objc private func back() { /* (contentViewController as? MainViewController)?.goBack()*/ }
    @objc private func forward() { /* (contentViewController as? MainViewController)?.goForward() */ }
    @objc private func run() { /* (contentViewController as? MainViewController)?.runSomething() */ }

    // MARK: NSToolbarDelegate (start with items that sit next to the traffic lights)

    func toolbarAllowedItemIdentifiers(_: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.navGroup, .flexibleSpace, .searchItem]
    }

    func toolbarDefaultItemIdentifiers(_: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.navGroup, .flexibleSpace, .searchItem]
    }

    func toolbar(
        _: NSToolbar,
        itemForItemIdentifier id: NSToolbarItem.Identifier,
        willBeInsertedIntoToolbar _: Bool,
    ) -> NSToolbarItem? {
        switch id {
        case .navGroup:
            let backBtn = NSButton(title: "◀︎", target: self, action: #selector(back))
            backBtn.bezelStyle = .toolbar
            let fwdBtn = NSButton(title: "▶︎", target: self, action: #selector(forward))
            fwdBtn.bezelStyle = .toolbar

            let stack = NSStackView(views: [backBtn, fwdBtn])
            stack.orientation = .horizontal
            stack.spacing = 4

            let item = NSToolbarItem(itemIdentifier: id)
            item.view = stack
            return item

        case .searchItem:
            let field = NSSearchField(frame: NSRect(x: 0, y: 0, width: 240, height: 0))
            let item = NSToolbarItem(itemIdentifier: id)
            item.view = field
            return item

        default:
            return nil
        }
    }
}

private extension NSToolbar.Identifier { static let mainToolbar = NSToolbar.Identifier("MainToolbar") }
private extension NSToolbarItem.Identifier {
    static let navGroup = NSToolbarItem.Identifier("NavGroup")
    static let searchItem = NSToolbarItem.Identifier("SearchItem")
}
