import AppKit
import Foundation
import SwiftDeclaration

public final class AppViewController: NSSplitViewController {
    private var rootDirectory: RootDirectory {
        didSet {
            fileTreeViewController.update(with: rootDirectory.directory)
        }
    }

    private let fileTreeViewController: FileTreeViewController
    private let scrollViewControlelr: ScrollViewController
    private var sidebarSplitViewItem: NSSplitViewItem?
    private var didSetInitialSidebarWidth = false

    public init(rootDirectory: RootDirectory) {
        self.rootDirectory = rootDirectory
        fileTreeViewController = FileTreeViewController()
        scrollViewControlelr = ScrollViewController()
        super.init(nibName: nil, bundle: nil)
        configureCallbacks()
        scrollViewControlelr.updateRootDirectory(rootDirectory)
    }

    public required init?(coder: NSCoder) {
        let defaultRootDirectory = RootDirectory.dummy
        rootDirectory = defaultRootDirectory
        fileTreeViewController = FileTreeViewController()
        scrollViewControlelr = ScrollViewController()
        super.init(coder: coder)
        configureCallbacks()
        scrollViewControlelr.updateRootDirectory(defaultRootDirectory)
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        setupSplitView()
    }

    override public func viewDidLayout() {
        super.viewDidLayout()
        setInitialSidebarWidthIfNeeded()
    }

    public func updateRootDirectory(_ newRootDirectory: RootDirectory) {
        rootDirectory = newRootDirectory
        scrollViewControlelr.updateRootDirectory(newRootDirectory)
    }

    private func setupSplitView() {
        guard splitViewItems.isEmpty else {
            return
        }

        splitView.isVertical = true
        splitView.dividerStyle = .thin

        let sidebarItem = NSSplitViewItem(sidebarWithViewController: fileTreeViewController)
        sidebarItem.minimumThickness = 250
        sidebarItem.maximumThickness = 800
        sidebarItem.canCollapse = true
        sidebarItem.allowsFullHeightLayout = true
        sidebarSplitViewItem = sidebarItem

        addSplitViewItem(sidebarItem)
        addSplitViewItem(NSSplitViewItem(viewController: scrollViewControlelr))
    }

    private func setInitialSidebarWidthIfNeeded() {
        guard !didSetInitialSidebarWidth,
              splitViewItems.count > 1 else {
            return
        }

        splitView.setPosition(300, ofDividerAt: 0)
        didSetInitialSidebarWidth = true
    }

    public func toggleSidebarVisibility() {
        if !isViewLoaded {
            _ = view
        }

        guard let sidebarItem = sidebarSplitViewItem else {
            return
        }

        let shouldCollapse = !sidebarItem.isCollapsed
        sidebarItem.animator().isCollapsed = shouldCollapse
    }

    private func configureCallbacks() {
        fileTreeViewController.onFileSelected = { [weak self] file in
            self?.scrollViewControlelr.resetToSingleColumnDisplaying(
                declarations: file.topDeclarations,
                headerTitle: file.fullPath,
            )
        }
        fileTreeViewController.onSelectionCleared = {}
    }
}
