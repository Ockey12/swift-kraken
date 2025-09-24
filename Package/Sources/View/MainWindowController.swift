//
//  MainWindowController.swift
//  Package
//
//  Created by Ockey on 2025/09/19.
//

import AppKit
import Dependencies
import SwiftDeclaration

final class MainWindowController: NSWindowController, NSToolbarDelegate {
    private lazy var appViewController = AppViewController(rootDirectory: .dummy)

    // MARK: Directory Selection State

    private var swiftDirectoryURL: URL?
    private var indexStoreDirectoryURL: URL?

    private weak var swiftDirectoryButton: DirectorySelectionButton?
    private weak var indexStoreDirectoryButton: DirectorySelectionButton?
    private weak var runButton: NSButton?

    @Dependency(\.rootDirectoryClient) private var rootDirectoryClient

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
        [
            .toggleSidebar,
            .flexibleSpace,
            .runAnalysis,
            .sidebarTrackingSeparator,
            .swiftDirectorySelection,
            .space,
            .indexStoreDirectorySelection,
            .flexibleSpace,
        ]
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

        case .runAnalysis:
            let item = NSToolbarItem(itemIdentifier: id)
            item.image = NSImage(systemSymbolName: "play.fill", accessibilityDescription: "Run Analysis")
            item.toolTip = "Run analysis."
            item.action = #selector(runAnalysis)
            return item

        case .swiftDirectorySelection:
            let button = DirectorySelectionButton(
                defaultToolTip: "Choose the Swift project or package directory.",
                target: self,
                action: #selector(chooseSwiftDirectory),
            )
            button.image = NSImage(systemSymbolName: "swift", accessibilityDescription: "Swift Directory")
            button.update(path: swiftDirectoryURL?.path())
            swiftDirectoryButton = button
            let item = NSToolbarItem(itemIdentifier: id)
            item.view = button
            item.image = NSImage(systemSymbolName: "swift", accessibilityDescription: "Swift Directory")

            return item

        case .indexStoreDirectorySelection:
            let button = DirectorySelectionButton(
                defaultToolTip: "Choose the Swift project or package directory.",
                target: self,
                action: #selector(chooseIndexStoreDirectory),
            )
            button.image = NSImage(systemSymbolName: "folder.fill.badge.gearshape", accessibilityDescription: "IndexStore Directory")
            button.update(path: indexStoreDirectoryURL?.path())
            indexStoreDirectoryButton = button
            let item = NSToolbarItem(itemIdentifier: id)
            item.view = button
            return item

        default:
            return nil
        }
    }

    // MARK: - Directory Selection

    @objc private func chooseSwiftDirectory() {
        guard let w = window else {
            return
        }
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false
        panel.prompt = "Choose"
        panel.message = "Choose the Swift project or package directory."
        if let url = swiftDirectoryURL {
            panel.directoryURL = url
        }
        panel.beginSheetModal(for: w) { [weak self] response in
            guard let self else {
                return
            }
            if response == .OK, let url = panel.url {
                swiftDirectoryURL = url
                swiftDirectoryButton?.update(path: url.path())
            }
        }
    }

    @objc private func chooseIndexStoreDirectory() {
        guard let w = window else {
            return
        }
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false
        panel.prompt = "Choose"
        panel.message = "Choose the IndexStore DataStore directory."
        if let url = indexStoreDirectoryURL {
            panel.directoryURL = url
        }
        panel.beginSheetModal(for: w) { [weak self] response in
            guard let self else {
                return
            }
            if response == .OK, let url = panel.url {
                indexStoreDirectoryURL = url
                indexStoreDirectoryButton?.update(path: url.path())
            }
        }
    }

    @objc private func runAnalysis() {
        tryBuildRootDirectoryIfReady()
    }

    private func tryBuildRootDirectoryIfReady() {
        guard let swiftURL = swiftDirectoryURL, let indexURL = indexStoreDirectoryURL else {
            return
        }
        // Kick async extraction
        Task {
            do {
                let root = try await rootDirectoryClient.extract(swiftURL, indexURL)
                await MainActor.run {
                    self.appViewController.updateRootDirectory(root)
                }
            } catch {
                await MainActor.run {
                    let alert = NSAlert(error: error)
                    alert.messageText = "Failed to analyze…"
                    alert.informativeText = error.localizedDescription
                    alert.beginSheetModal(for: self.window!)
                }
            }
        }
    }
}

private extension NSToolbar.Identifier {
    static let mainToolbar = NSToolbar.Identifier("MainToolbar")
}

private extension NSToolbarItem.Identifier {
    static let runAnalysis = NSToolbarItem.Identifier("RunAnalysis")
    static let swiftDirectorySelection = NSToolbarItem.Identifier("SwiftDirectorySelection")
    static let indexStoreDirectorySelection = NSToolbarItem.Identifier("IndexStoreDirectorySelection")
}

private final class DirectorySelectionButton: NSButton {
    private static let placeholder = "Choose directory"
    private var defaultToolTip: String

    init(defaultToolTip: String, target: AnyObject?, action: Selector) {
        self.defaultToolTip = defaultToolTip
        super.init(frame: .zero)

        imagePosition = .imageLeading
        self.target = target
        self.action = action
        update(path: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(path: String?) {
        if let path {
            title = URL(fileURLWithPath: path).lastPathComponent
            toolTip = path
        } else {
            title = Self.placeholder
            toolTip = defaultToolTip
        }

        needsLayout = true
    }
}
