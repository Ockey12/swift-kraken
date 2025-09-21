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
    private var dragStartLeftWidth: CGFloat = 0

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

        NSLayoutConstraint.activate([
            leftWidthConstraint,
            dividerView.widthAnchor.constraint(equalToConstant: 10),
            centerView.widthAnchor.constraint(equalToConstant: 500),
            rightView.widthAnchor.constraint(equalToConstant: 500),
        ])

        let panGesture = NSPanGestureRecognizer(target: self, action: #selector(handleDividerPan(_:)))
        dividerView.addGestureRecognizer(panGesture)
    }

    @objc
    private func handleDividerPan(_ gesture: NSPanGestureRecognizer) {
        let translation = gesture.translation(in: view)

        switch gesture.state {
        case .began:
            dragStartLeftWidth = leftWidthConstraint.constant

        case .changed:
            let newWidth = max(0, dragStartLeftWidth + translation.x)
            leftWidthConstraint.constant = newWidth
            view.layoutSubtreeIfNeeded()

        case .ended, .cancelled:
            let newWidth = max(0, dragStartLeftWidth + translation.x)
            leftWidthConstraint.constant = newWidth

        default:
            break
        }
    }
}
