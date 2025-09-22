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

        w.contentViewController = appViewController

        // Merge title bar and toolbar
        w.titleVisibility = .hidden
        w.titlebarAppearsTransparent = true
        w.styleMask.insert(.fullSizeContentView)
        w.toolbarStyle = .unified

        // Toolbar (same row as the window controls)
        let tb = NSToolbar(identifier: .mainToolbar)
        tb.delegate = self
        tb.displayMode = .iconOnly
        tb.allowsUserCustomization = true
        w.toolbar = tb
    }

    // MARK: Actions (bridging into the view controller)

    @objc private func toggleSidebar() {
        appViewController.toggleSidebarVisibility()
    }

    // MARK: NSToolbarDelegate (start with items that sit next to the traffic lights)

    func toolbarAllowedItemIdentifiers(_: NSToolbar) -> [NSToolbarItem.Identifier] {
        []
    }

    func toolbarDefaultItemIdentifiers(_: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.toggleSidebar, .sidebarTrackingSeparator, .flexibleSpace, .centerTitle, .flexibleSpace]
    }

    func toolbar(
        _: NSToolbar,
        itemForItemIdentifier id: NSToolbarItem.Identifier,
        willBeInsertedIntoToolbar _: Bool,
    ) -> NSToolbarItem? {
        switch id {
        case .sidebarTrackingSeparator:
            return NSTrackingSeparatorToolbarItem(
                identifier: .sidebarTrackingSeparator,
                splitView: appViewController.splitView,
                dividerIndex: 0,
            )

        case .centerTitle:
            let label = NSTextField(labelWithString: "Swift")
            label.font = NSFont.systemFont(ofSize: NSFont.systemFontSize(for: .large), weight: .semibold)
            label.alignment = .center
            label.textColor = NSColor.labelColor
            label.translatesAutoresizingMaskIntoConstraints = false
            label.setContentHuggingPriority(.required, for: .horizontal)
            label.setContentHuggingPriority(.defaultHigh, for: .vertical)

            let container = NSView()
            container.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(label)

            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                container.heightAnchor.constraint(equalToConstant: 32),
            ])

            let item = NSToolbarItem(itemIdentifier: id)
            item.view = container
            return item

        default:
            return nil
        }
    }
}

private extension NSToolbar.Identifier { static let mainToolbar = NSToolbar.Identifier("MainToolbar") }
private extension NSToolbarItem.Identifier {
    static let navGroup = NSToolbarItem.Identifier("NavGroup")
    static let centerTitle = NSToolbarItem.Identifier("CenterTitle")
}
