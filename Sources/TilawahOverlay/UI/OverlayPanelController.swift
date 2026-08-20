import AppKit
import SwiftUI

@MainActor
final class OverlayPanelController: NSObject, NSWindowDelegate {
    private var panel: NSPanel?
    private var hostingView: NSHostingView<AnyView>?
    private let frameDefaultsKey = "overlay.frame"

    var isVisible: Bool {
        panel?.isVisible == true
    }

    func show<Content: View>(@ViewBuilder content: () -> Content) {
        let rootView = AnyView(content())

        if panel == nil {
            let saved = savedFrame() ?? NSRect(x: 0, y: 0, width: 380, height: 440)
            let panel = FloatingPanel(
                contentRect: saved,
                styleMask: [.nonactivatingPanel, .titled, .closable, .resizable, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )

            panel.title = "Tilawah"
            panel.titlebarAppearsTransparent = true
            panel.titleVisibility = .hidden
            panel.isMovableByWindowBackground = true
            panel.isFloatingPanel = true
            panel.level = .floating
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            panel.becomesKeyOnlyIfNeeded = true
            panel.hidesOnDeactivate = false
            panel.isReleasedWhenClosed = false
            panel.backgroundColor = NSColor.windowBackgroundColor.withAlphaComponent(0.92)
            panel.minSize = NSSize(width: 280, height: 180)
            panel.maxSize = NSSize(width: 1400, height: 1000)
            panel.delegate = self

            if savedFrame() == nil {
                panel.center()
            }

            let hostingView = NSHostingView(rootView: rootView)
            hostingView.frame = panel.contentView?.bounds ?? saved
            hostingView.autoresizingMask = [.width, .height]
            panel.contentView = hostingView

            self.panel = panel
            self.hostingView = hostingView
        } else {
            hostingView?.rootView = rootView
        }

        panel?.orderFrontRegardless()
    }

    func hide() {
        persistFrame()
        panel?.orderOut(nil)
    }

    func toggle<Content: View>(@ViewBuilder content: () -> Content) {
        if isVisible {
            hide()
        } else {
            show(content: content)
        }
    }

    func windowDidResize(_ notification: Notification) {
        persistFrame()
    }

    func windowDidMove(_ notification: Notification) {
        persistFrame()
    }

    func windowWillClose(_ notification: Notification) {
        persistFrame()
    }

    private func persistFrame() {
        guard let panel, panel.frame.width > 0, panel.frame.height > 0 else { return }
        UserDefaults.standard.set(NSStringFromRect(panel.frame), forKey: frameDefaultsKey)
    }

    private func savedFrame() -> NSRect? {
        guard let raw = UserDefaults.standard.string(forKey: frameDefaultsKey) else { return nil }
        let frame = NSRectFromString(raw)
        guard frame.width >= 220, frame.height >= 160 else { return nil }
        return frame
    }
}

private final class FloatingPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
