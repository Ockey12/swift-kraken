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

    @objc private func toggleSidebar() {
        appViewController.toggleSidebarVisibility()
    }

    // MARK: NSToolbarDelegate (start with items that sit next to the traffic lights)

    func toolbarAllowedItemIdentifiers(_: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.navGroup]
    }

    func toolbarDefaultItemIdentifiers(_: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.navGroup]
    }

    func toolbar(
        _: NSToolbar,
        itemForItemIdentifier id: NSToolbarItem.Identifier,
        willBeInsertedIntoToolbar _: Bool,
    ) -> NSToolbarItem? {
        switch id {
        case .navGroup:
            let toggleSidebarBtn: NSButton
            if #available(macOS 11.0, *) {
                let image = NSImage(systemSymbolName: "sidebar.left", accessibilityDescription: "Toggle Sidebar")
                    ?? NSImage(named: NSImage.touchBarSidebarTemplateName)
                    ?? NSImage()
                toggleSidebarBtn = NSButton(image: image, target: self, action: #selector(toggleSidebar))
                toggleSidebarBtn.imageScaling = .scaleProportionallyDown
            } else {
                toggleSidebarBtn = NSButton(title: "☰", target: self, action: #selector(toggleSidebar))
            }
            toggleSidebarBtn.bezelStyle = .toolbar
            toggleSidebarBtn.toolTip = "Toggle File Tree"

            let stack = NSStackView(views: [toggleSidebarBtn])
            stack.orientation = .horizontal
            stack.spacing = 4

            let item = NSToolbarItem(itemIdentifier: id)
            item.view = stack
            return item

        default:
            return nil
        }
    }
}

private extension NSToolbar.Identifier { static let mainToolbar = NSToolbar.Identifier("MainToolbar") }
private extension NSToolbarItem.Identifier {
    static let navGroup = NSToolbarItem.Identifier("NavGroup")
}
