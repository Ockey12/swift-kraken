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
//    private let columnsWrapperViewController: MySplitViewController
    private let scrollViewControlelr: ScrollViewController
    private var sidebarSplitViewItem: NSSplitViewItem?
    private var didSetInitialSidebarWidth = false

    public init(rootDirectory: RootDirectory) {
        self.rootDirectory = rootDirectory
        fileTreeViewController = FileTreeViewController(rootDirectory: rootDirectory.directory)
//        columnsWrapperViewController = MySplitViewController()
        scrollViewControlelr = ScrollViewController()
        super.init(nibName: nil, bundle: nil)
        configureCallbacks()
    }

    public required init?(coder: NSCoder) {
        let defaultRootDirectory = RootDirectory.dummy
        rootDirectory = defaultRootDirectory
        fileTreeViewController = FileTreeViewController(rootDirectory: defaultRootDirectory.directory)
//        columnsWrapperViewController = MySplitViewController()
        scrollViewControlelr = ScrollViewController()
        super.init(coder: coder)
        configureCallbacks()
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

//        let contentItem = NSSplitViewItem(viewController: columnsWrapperViewController)

        addSplitViewItem(sidebarItem)
//        addSplitViewItem(contentItem)
        addSplitViewItem(NSSplitViewItem(viewController: scrollViewControlelr))

//        columnsWrapperViewController.clearRootDeclarations()
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
            self?.displayDeclarations(from: file)
        }
        fileTreeViewController.onSelectionCleared = {}
    }

    private func displayDeclarations(from _: File) {
//        columnsWrapperViewController.display(declarations: Array(file.abstractDeclarations))
    }
}

private final class FileTreeViewController: NSViewController {
    typealias FileSelectionHandler = (File) -> Void

    var onFileSelected: FileSelectionHandler?
    var onSelectionCleared: (() -> Void)?

    private var topLevelNodes: [FileSystemNode]
    private let scrollView = NSScrollView()
    private let outlineView = NSOutlineView()

    private enum Constants {
        static let columnIdentifier = NSUserInterfaceItemIdentifier("FileTreeColumn")
        static let cellIdentifier = NSUserInterfaceItemIdentifier("FileTreeCell")
    }

    init(rootDirectory: Directory) {
        topLevelNodes = FileTreeViewController.makeRootNodes(for: rootDirectory)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let effectView = NSVisualEffectView()
        effectView.material = .sidebar
        effectView.state = .active
        effectView.blendingMode = .behindWindow
        view = effectView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupOutlineView()
        outlineView.reloadData()
    }

    func update(with directory: Directory) {
        topLevelNodes = FileTreeViewController.makeRootNodes(for: directory)
        if isViewLoaded {
            outlineView.reloadData()
        }
        onSelectionCleared?()
    }

    private func setupOutlineView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false

        outlineView.dataSource = self
        outlineView.delegate = self
        outlineView.headerView = nil
        outlineView.columnAutoresizingStyle = .firstColumnOnlyAutoresizingStyle
        outlineView.usesAlternatingRowBackgroundColors = false
        outlineView.backgroundColor = .clear
        outlineView.allowsMultipleSelection = false
        outlineView.allowsEmptySelection = true
        outlineView.rowSizeStyle = .default

        let column = NSTableColumn(identifier: Constants.columnIdentifier)
        column.title = "Files"
        column.minWidth = 160
        column.resizingMask = .autoresizingMask
        outlineView.addTableColumn(column)
        outlineView.outlineTableColumn = column

        scrollView.documentView = outlineView
        view.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
}

extension FileTreeViewController: NSOutlineViewDataSource {
    func outlineView(_: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        guard let node = item as? FileSystemNode else {
            return topLevelNodes.count
        }
        return node.children.count
    }

    func outlineView(_: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        guard let node = item as? FileSystemNode else {
            return topLevelNodes[index]
        }
        return node.children[index]
    }

    func outlineView(_: NSOutlineView, isItemExpandable item: Any) -> Bool {
        guard let node = item as? FileSystemNode else {
            return false
        }
        return node.isDirectory
    }
}

extension FileTreeViewController: NSOutlineViewDelegate {
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard tableColumn?.identifier == Constants.columnIdentifier,
              let node = item as? FileSystemNode else {
            return nil
        }

        let cellView: NSTableCellView
        if let reused = outlineView.makeView(withIdentifier: Constants.cellIdentifier, owner: self) as? NSTableCellView {
            cellView = reused
        } else {
            cellView = NSTableCellView()
            cellView.identifier = Constants.cellIdentifier

            let imageView = NSImageView()
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 14, weight: .regular)
            cellView.addSubview(imageView)
            cellView.imageView = imageView

            let textField = NSTextField(labelWithString: "")
            textField.translatesAutoresizingMaskIntoConstraints = false
            cellView.addSubview(textField)
            cellView.textField = textField

            NSLayoutConstraint.activate([
                imageView.leadingAnchor.constraint(equalTo: cellView.leadingAnchor, constant: 4),
                imageView.centerYAnchor.constraint(equalTo: cellView.centerYAnchor),
                imageView.widthAnchor.constraint(equalToConstant: 16),
                imageView.heightAnchor.constraint(equalToConstant: 16),

                textField.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 6),
                textField.trailingAnchor.constraint(equalTo: cellView.trailingAnchor, constant: -4),
                textField.centerYAnchor.constraint(equalTo: cellView.centerYAnchor),
            ])
        }

        cellView.textField?.stringValue = node.displayName
        cellView.imageView?.image = NSImage(systemSymbolName: node.systemSymbolName, accessibilityDescription: node.displayName)
        cellView.imageView?.contentTintColor = node.systemSymbolTintColor
        return cellView
    }

    func outlineViewSelectionDidChange(_ notification: Notification) {
        guard let outlineView = notification.object as? NSOutlineView,
              outlineView === self.outlineView else {
            return
        }

        let selectedRow = outlineView.selectedRow
        guard selectedRow >= 0,
              let node = outlineView.item(atRow: selectedRow) as? FileSystemNode else {
            onSelectionCleared?()
            return
        }

        if let file = node.file {
            onFileSelected?(file)
        } else {
            onSelectionCleared?()
        }
    }
}

private final class FileSystemNode: NSObject {
    enum Content {
        case directory(Directory)
        case file(File)
    }

    let content: Content
    let children: [FileSystemNode]

    init(content: Content, children: [FileSystemNode]) {
        self.content = content
        self.children = children
        super.init()
    }

    var displayName: String {
        switch content {
        case let .directory(directory):
            FileSystemNode.lastPathComponent(from: directory.fullPath)
        case let .file(file):
            FileSystemNode.lastPathComponent(from: file.fullPath)
        }
    }

    var isDirectory: Bool {
        if case .directory = content {
            return true
        }
        return false
    }

    private var hasChildren: Bool {
        switch content {
        case let .directory(directory):
            !directory.subDirectories.isEmpty || !directory.files.isEmpty
        case .file:
            false
        }
    }

    var file: File? {
        if case let .file(file) = content {
            return file
        }
        return nil
    }

    var systemSymbolName: String {
        switch content {
        case .directory:
            return hasChildren ? "folder.fill" : "folder"
        case let .file(file):
            if file.fullPath.hasSuffix(".swift") {
                return "swift"
            }
            return "doc"
        }
    }

    var systemSymbolTintColor: NSColor {
        switch content {
        case .directory:
            return NSColor(calibratedRed: 0.25, green: 0.70, blue: 0.98, alpha: 1.0)
        case let .file(file):
            if file.fullPath.hasSuffix(".swift") {
                return NSColor(calibratedRed: 0.94, green: 0.32, blue: 0.22, alpha: 1.0)
            }
            return NSColor.secondaryLabelColor
        }
    }

    private static func lastPathComponent(from path: String) -> String {
        guard !path.isEmpty else {
            return "Root"
        }
        return URL(fileURLWithPath: path).lastPathComponent
    }
}

private extension FileTreeViewController {
    static func makeRootNodes(for directory: Directory) -> [FileSystemNode] {
        let children = makeChildNodes(for: directory)
        let rootNode = FileSystemNode(content: .directory(directory), children: children)
        return [rootNode]
    }

    static func makeChildNodes(for directory: Directory) -> [FileSystemNode] {
        let directoryNodes = directory.subDirectories.map { subDirectory -> FileSystemNode in
            let children = makeChildNodes(for: subDirectory)
            return FileSystemNode(content: .directory(subDirectory), children: children)
        }.sorted { lhs, rhs in
            lhs.displayName.localizedCaseInsensitiveCompare(rhs.displayName) == .orderedAscending
        }

        let fileNodes = directory.files.map { file -> FileSystemNode in
            FileSystemNode(content: .file(file), children: [])
        }.sorted { lhs, rhs in
            lhs.displayName.localizedCaseInsensitiveCompare(rhs.displayName) == .orderedAscending
        }

        return directoryNodes + fileNodes
    }
}
