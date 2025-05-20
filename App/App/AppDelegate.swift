//
//  AppDelegate.swift
//  App
//
//  Created by Ockey on 2025/05/21.
//

import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 270),
            styleMask: [.miniaturizable, .closable, .resizable, .titled],
            backing: .buffered, defer: false)
        window.center()
        window.title = "No Storyboard Window"
        window.contentView = NSHostingView(rootView: TextView())
        window.makeKeyAndOrderFront(nil)
    }
}

class MainViewController: NSViewController {
    override func loadView() {
        // ルートビューをコードのみで生成
        self.view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // 例：中央にラベルを配置する
        let label = NSTextField(labelWithString: "Hello, AppKit!")
        label.font = .systemFont(ofSize: 24, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}

struct TextView: View {
    var body: some View {
        Text("Hello, macOS!")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
