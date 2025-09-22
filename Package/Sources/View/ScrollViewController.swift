//
//  ScrollViewController.swift
//  Package
//
//  Created by Ockey on 2025/09/22.
//

import AppKit

@MainActor
final class ScrollViewController: NSViewController {
    private static let minColumnWidth: CGFloat = 250

    private var scrollView: NSScrollView!
    private var leftWidthConstraint: NSLayoutConstraint!
    private var rightWidthConstraint: NSLayoutConstraint!
    private var leftViewWidth: CGFloat = 500
    private var rightViewWidth: CGFloat = 0
    private var dragStartedAtRightEdge = false

    private var lastContentOffsetX: CGFloat = 0
    private var isRubberBandingOnRightEdge = false

    private var currentTranslationX: CGFloat = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = true
        scrollView.borderType = .noBorder
        view.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: 52),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        let stackView = NSStackView()
        stackView.orientation = .horizontal
        stackView.spacing = 0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = stackView
        scrollView.contentView.postsBoundsChangedNotifications = true
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(contentViewDidScroll(_:)),
            name: NSView.boundsDidChangeNotification,
            object: scrollView.contentView,
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(scrollViewDidEndLiveScroll(_:)),
            name: NSScrollView.didEndLiveScrollNotification,
            object: scrollView,
        )
        lastContentOffsetX = scrollView.contentView.bounds.origin.x

        let clipView = scrollView.contentView

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: clipView.leadingAnchor),
            stackView.topAnchor.constraint(equalTo: clipView.topAnchor),
            stackView.heightAnchor.constraint(equalTo: clipView.heightAnchor),
        ])

        let leftView = NSView()
        leftView.translatesAutoresizingMaskIntoConstraints = false
        leftView.wantsLayer = true
        leftView.layer?.backgroundColor = NSColor.systemRed.cgColor

        let dividerView = NSView()
        dividerView.translatesAutoresizingMaskIntoConstraints = false
        dividerView.wantsLayer = true
        dividerView.layer?.backgroundColor = NSColor.white.cgColor

        let centerView = NSView()
        centerView.translatesAutoresizingMaskIntoConstraints = false
        centerView.wantsLayer = true
        centerView.layer?.backgroundColor = NSColor.systemBlue.cgColor

        let rightView = NSView()
        rightView.translatesAutoresizingMaskIntoConstraints = false
        rightView.wantsLayer = true
        rightView.layer?.backgroundColor = NSColor.systemGreen.cgColor

        stackView.addArrangedSubview(leftView)
        stackView.addArrangedSubview(dividerView)
        stackView.addArrangedSubview(centerView)
        stackView.addArrangedSubview(rightView)

        leftWidthConstraint = leftView.widthAnchor.constraint(equalToConstant: leftViewWidth)
        rightWidthConstraint = rightView.widthAnchor.constraint(equalToConstant: rightViewWidth)

        NSLayoutConstraint.activate([
            leftWidthConstraint,
            dividerView.widthAnchor.constraint(equalToConstant: 10),
            centerView.widthAnchor.constraint(equalToConstant: 500),
            rightWidthConstraint,
        ])

        let panGesture = NSPanGestureRecognizer(target: self, action: #selector(handleDividerPan(_:)))
        dividerView.addGestureRecognizer(panGesture)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc
    private func handleDividerPan(_ gesture: NSPanGestureRecognizer) {
        let translationX = gesture.translation(in: view).x
        let delta = translationX - currentTranslationX

        switch gesture.state {
        case .began:
            dragStartedAtRightEdge = isScrolledToRightEdge()

        case .changed:
            dragStartedAtRightEdge = isScrolledToRightEdge()
            applyWidths(for: delta, shouldLayout: true)

        default:
            break
        }

        currentTranslationX = translationX
    }

    @objc
    private func contentViewDidScroll(_: Notification) {
        guard scrollView != nil else {
            return
        }
        let currentOffsetX = scrollView.contentView.bounds.origin.x
        let delta = currentOffsetX - lastContentOffsetX
        lastContentOffsetX = currentOffsetX

        updateRubberBandingState()

        guard delta < 0 else {
            return
        }

        let currentRightWidth = rightWidthConstraint.constant
        guard currentRightWidth > 0 else {
            return
        }

        guard isRubberBandingOnRightEdge == false else {
            return
        }

        let shrinkAmount = min(-delta, currentRightWidth)
        guard shrinkAmount > 0 else {
            return
        }

        rightWidthConstraint.constant = currentRightWidth - shrinkAmount
        view.layoutSubtreeIfNeeded()
    }

    private func applyWidths(for delta: CGFloat, shouldLayout: Bool) {
        let widths = calculateWidths(for: delta)

        leftViewWidth = widths.left
        leftWidthConstraint.constant = widths.left

        rightViewWidth = widths.right
        rightWidthConstraint.constant = widths.right

        if shouldLayout {
            view.layoutSubtreeIfNeeded()
        }
    }

    private func calculateWidths(for delta: CGFloat) -> (left: CGFloat, right: CGFloat) {
        let newLeftWidth = max(Self.minColumnWidth, leftViewWidth + delta)
        var newRightWidth = rightViewWidth

        if rightViewWidth > 0,
           delta > 0 {
            newRightWidth = max(0, rightViewWidth - delta)
            return (newLeftWidth, newRightWidth)
        }

        if dragStartedAtRightEdge,
           delta < 0 {
            newRightWidth = max(0, rightViewWidth - delta)
            return (newLeftWidth, newRightWidth)
        }

        return (newLeftWidth, rightViewWidth)
    }

    private func isScrolledToRightEdge() -> Bool {
        guard let documentView = scrollView.documentView else {
            return false
        }

        let visibleRect = scrollView.documentVisibleRect
        let documentWidth = documentView.bounds.width

        if documentWidth <= visibleRect.width {
            return false
        }

        return visibleRect.maxX == documentWidth
    }

    private func updateRubberBandingState() {
        guard let documentView = scrollView.documentView else {
            isRubberBandingOnRightEdge = false
            return
        }

        let visibleRect = scrollView.documentVisibleRect
        let documentWidth = documentView.bounds.width

        if visibleRect.maxX > documentWidth {
            isRubberBandingOnRightEdge = true
        } else if visibleRect.maxX <= documentWidth - 1 {
            isRubberBandingOnRightEdge = false
        }
    }

    @objc
    private func scrollViewDidEndLiveScroll(_: Notification) {
        updateRubberBandingState()
    }
}
