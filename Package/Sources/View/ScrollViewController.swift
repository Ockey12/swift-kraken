//
//  ScrollViewController.swift
//  Package
//
//  Created by Ockey on 2025/09/22.
//

import AppKit

@MainActor
final class ScrollViewController: NSViewController {
    private var scrollView: NSScrollView!
    private var leftWidthConstraint: NSLayoutConstraint!
    private var rightWidthConstraint: NSLayoutConstraint!
    private var dragStartLeftWidth: CGFloat = 0
    private var dragStartRightWidth: CGFloat = 0
    private var dragStartedAtRightEdge = false
    private var lastContentOffsetX: CGFloat = 0
    private var isRubberBandingOnRightEdge = false

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

        leftWidthConstraint = leftView.widthAnchor.constraint(equalToConstant: 500)
        rightWidthConstraint = rightView.widthAnchor.constraint(equalToConstant: 0)

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

        switch gesture.state {
        case .began:
            dragStartLeftWidth = leftWidthConstraint.constant
            dragStartRightWidth = rightWidthConstraint.constant
            dragStartedAtRightEdge = isScrolledToRightEdge()

        case .changed:
            applyWidths(for: translationX, shouldLayout: true)

        case .ended, .cancelled:
            applyWidths(for: translationX, shouldLayout: true)

        default:
            break
        }
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

    private func applyWidths(for translation: CGFloat, shouldLayout: Bool) {
        let widths = calculateWidths(for: translation)
        leftWidthConstraint.constant = widths.left
        rightWidthConstraint.constant = widths.right

        if shouldLayout {
            view.layoutSubtreeIfNeeded()
        }
    }

    private func calculateWidths(for translation: CGFloat) -> (left: CGFloat, right: CGFloat) {
        var newLeftWidth = dragStartLeftWidth
        var newRightWidth = dragStartRightWidth

        if translation >= 0 {
            let leftIncrease = translation
            newLeftWidth += leftIncrease

            if dragStartRightWidth > 0 {
                let rightDecrease = min(leftIncrease, dragStartRightWidth)
                newRightWidth -= rightDecrease
            }
        } else {
            let targetLeftWidth = max(0, dragStartLeftWidth + translation)
            let actualLeftDecrease = dragStartLeftWidth - targetLeftWidth
            newLeftWidth = targetLeftWidth

            if dragStartedAtRightEdge {
                newRightWidth += actualLeftDecrease
            }
        }

        return (max(0, newLeftWidth), max(0, newRightWidth))
    }

    private func isScrolledToRightEdge() -> Bool {
        guard let documentView = scrollView.documentView else {
            return true
        }

        let visibleRect = scrollView.documentVisibleRect
        let documentWidth = documentView.bounds.width
        let epsilon: CGFloat = 1.0

        if documentWidth <= visibleRect.width + epsilon {
            return true
        }

        return visibleRect.maxX >= documentWidth - epsilon
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
