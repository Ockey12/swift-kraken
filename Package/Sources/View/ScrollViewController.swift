//
//  ScrollViewController.swift
//  Package
//
//  Created by Ockey on 2025/09/22.
//

import AppKit

final class ScrollViewController: NSViewController {
    private var scrollView: NSScrollView!
    private var leftWidthConstraint: NSLayoutConstraint!
    private var rightWidthConstraint: NSLayoutConstraint!
    private var dragStartLeftWidth: CGFloat = 0
    private var dragStartRightWidth: CGFloat = 0
    private var dragStartedAtRightEdge = false

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
            return false
        }

        guard documentView.visibleRect.minX != 0 else {
            return false
        }

        return documentView.visibleRect.maxX >= documentView.bounds.maxX - 0.5
    }
}
