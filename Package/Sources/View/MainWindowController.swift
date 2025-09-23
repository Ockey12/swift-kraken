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

    private weak var swiftPathLabel: NSTextField?
    private weak var indexStorePathLabel: NSTextField?
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
            .swiftDirectoryButton,
            .swiftDirectoryPath,
            .space,
            .indexStoreDirectoryButton,
            .indexStoreDirectoryPath,
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
            let button = NSButton(title: "", target: self, action: #selector(runAnalysis))
            button.image = NSImage(systemSymbolName: "play.fill", accessibilityDescription: "Run Analysis")
            button.imagePosition = .imageOnly
            button.bezelStyle = .texturedRounded
            button.toolTip = "Run analysis."
            let item = NSToolbarItem(itemIdentifier: id)
            item.view = button
            runButton = button
            return item

        case .swiftDirectoryButton:
            let button = NSButton(title: "Swift", target: self, action: #selector(chooseSwiftDirectory))
            button.image = NSImage(systemSymbolName: "folder", accessibilityDescription: "Swift Directory")
            button.imagePosition = .imageLeading
            button.bezelStyle = .texturedRounded
            let item = NSToolbarItem(itemIdentifier: id)
            item.toolTip = "Choose the Swift project or package directory."
            item.view = button
            return item

        case .swiftDirectoryPath:
            let label = NSTextField(labelWithString: "")
            label.lineBreakMode = .byTruncatingMiddle
            label.translatesAutoresizingMaskIntoConstraints = false
            label.setContentHuggingPriority(.defaultLow, for: .horizontal)
            label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            let container = NSView()
            container.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(label)
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                label.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                container.heightAnchor.constraint(equalToConstant: 32),
                container.widthAnchor.constraint(greaterThanOrEqualToConstant: 180),
            ])
            swiftPathLabel = label
            let item = NSToolbarItem(itemIdentifier: id)
            item.view = container
            return item

        case .indexStoreDirectoryButton:
            let button = NSButton(title: "DataStore", target: self, action: #selector(chooseIndexStoreDirectory))
            button.image = NSImage(systemSymbolName: "folder", accessibilityDescription: "IndexStore Directory")
            button.imagePosition = .imageLeading
            button.bezelStyle = .texturedRounded
            let item = NSToolbarItem(itemIdentifier: id)
            item.toolTip = "Choose the IndexStore DataStore directory."
            item.view = button
            return item

        case .indexStoreDirectoryPath:
            let label = NSTextField(labelWithString: "")
            label.lineBreakMode = .byTruncatingMiddle
            label.translatesAutoresizingMaskIntoConstraints = false
            label.setContentHuggingPriority(.defaultLow, for: .horizontal)
            label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            let container = NSView()
            container.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(label)
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                label.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                container.heightAnchor.constraint(equalToConstant: 32),
                container.widthAnchor.constraint(greaterThanOrEqualToConstant: 180),
            ])
            indexStorePathLabel = label
            let item = NSToolbarItem(itemIdentifier: id)
            item.view = container
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
                swiftPathLabel?.stringValue = url.path()
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
                indexStorePathLabel?.stringValue = url.path()
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
    static let swiftDirectoryButton = NSToolbarItem.Identifier("SwiftDirectoryButton")
    static let swiftDirectoryPath = NSToolbarItem.Identifier("SwiftDirectoryPath")
    static let indexStoreDirectoryButton = NSToolbarItem.Identifier("IndexStoreDirectoryButton")
    static let indexStoreDirectoryPath = NSToolbarItem.Identifier("IndexStoreDirectoryPath")
}
