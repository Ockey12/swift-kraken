//
//  EmptyTest.swift
//  MainViewController
//
//  Created by Ockey on 2025/09/07.
//

import AppKit

public final class MainViewController: NSViewController {
    private lazy var infoLabel: NSTextField = {
        let label = NSTextField(labelWithString: "This is the Package MainViewController")
        label.font = NSFont.systemFont(ofSize: 18, weight: .medium)
        label.alignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(infoLabel)
        NSLayoutConstraint.activate([
            infoLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            infoLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    public override func viewDidAppear() {
        super.viewDidAppear()
        view.window?.title = "Swift-Kraken"
    }
}
