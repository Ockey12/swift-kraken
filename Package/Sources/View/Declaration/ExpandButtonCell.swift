//
//  ExpandButtonCell.swift
//  Package
//
//  Created by Ockey on 2025/09/15.
//

import AppKit

final class ExpandButtonCell: NSTableCellView {
    private var state: DeclarationCellState?
    private var button: NSButton!
    var onClicked: ((DeclarationCellState) -> Void)?

    private func setupView() {
        button = NSButton()

        if let symbolImage = NSImage(systemSymbolName: "arrow.right.circle.fill", accessibilityDescription: "Branch") {
            button.image = symbolImage
        } else {
            button.title = ""
        }

        button.isBordered = false
        button.target = self
        button.translatesAutoresizingMaskIntoConstraints = false
        addSubview(button)

        NSLayoutConstraint.activate([
            button.trailingAnchor.constraint(equalTo: trailingAnchor),
            button.centerYAnchor.constraint(equalTo: centerYAnchor),
            button.widthAnchor.constraint(equalToConstant: 24),
            button.heightAnchor.constraint(equalToConstant: 24)
        ])
    }

    @objc private func didClickedButton() {
        guard let state,
              state.hasChildren else {
            return
        }

        onClicked?(state)
    }

    func configure(with state: DeclarationCellState) {
        self.state = state
        button.isEnabled = state.hasChildren
        button.alphaValue = state.hasChildren ? 1 : 0.3
    }
}
