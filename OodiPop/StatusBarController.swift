import AppKit
import SwiftUI
import UniformTypeIdentifiers

final class StatusBarController: NSObject {
    private let store: OodiPopStore
    private let statusItem: NSStatusItem
    private let popover = NSPopover()
    private var previewWindowController: NSWindowController?
    private var openMediaObserver: NSObjectProtocol?

    init(store: OodiPopStore) {
        self.store = store
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()

        configurePopover()
        configureStatusItem()
        configureOpenMediaObserver()
    }

    deinit {
        if let openMediaObserver {
            NotificationCenter.default.removeObserver(openMediaObserver)
        }
    }

    private func configurePopover() {
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 420, height: 620)
        popover.contentViewController = NSHostingController(
            rootView: OodiPopMenuView()
                .environmentObject(store)
                .frame(width: 420, height: 620)
        )
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else { return }

        button.image = nil
        button.title = ""
        button.toolTip = "Oodi Pop"

        let dragView = StatusItemDragView(
            frame: button.bounds,
            onClick: { [weak self] in
                self?.togglePopover()
            },
            onDrop: { [weak self] url in
                self?.openPreview(for: url)
            }
        )
        dragView.autoresizingMask = [.width, .height]
        button.addSubview(dragView)
    }

    private func configureOpenMediaObserver() {
        openMediaObserver = NotificationCenter.default.addObserver(
            forName: .oodiPopOpenMediaRequested,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.openMediaFromPanel()
        }
    }

    private func togglePopover() {
        guard let button = statusItem.button else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    private func openPreview(for fileURL: URL) {
        guard let mediaKind = OodiPopMediaKind(fileURL: fileURL) else {
            showUnsupportedFileAlert()
            return
        }

        guard let catalog = store.catalog else {
            showLoadingAlert()
            return
        }

        popover.performClose(nil)

        let session = OodiPopPreviewSession(fileURL: fileURL, mediaKind: mediaKind, catalog: catalog)
        let rootView = PreviewWindowView(session: session)
        let hostingController = NSHostingController(rootView: rootView)
        let window = NSWindow(contentViewController: hostingController)
        window.title = ""
        window.setContentSize(NSSize(width: 980, height: 720))
        window.minSize = NSSize(width: 720, height: 520)
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.isReleasedWhenClosed = false
        window.center()

        let controller = NSWindowController(window: window)
        previewWindowController = controller
        controller.showWindow(nil)

        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    private func openMediaFromPanel() {
        popover.performClose(nil)

        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.image, .movie, .video, .audiovisualContent]
        panel.message = "Choose an image or video to preview across Oodi Pop sizes."

        guard panel.runModal() == .OK, let fileURL = panel.url else {
            return
        }

        openPreview(for: fileURL)
    }

    private func showUnsupportedFileAlert() {
        let alert = NSAlert()
        alert.messageText = "Unsupported file"
        alert.informativeText = "Drop an image or video file onto Oodi Pop."
        alert.alertStyle = .warning
        alert.runModal()
    }

    private func showLoadingAlert() {
        let alert = NSAlert()
        alert.messageText = "Catalog is still loading"
        alert.informativeText = "Try again in a moment."
        alert.alertStyle = .informational
        alert.runModal()
    }
}

private final class StatusItemDragView: NSView {
    private let onClick: () -> Void
    private let onDrop: (URL) -> Void
    private var isDragTargeted = false {
        didSet {
            needsDisplay = true
        }
    }

    init(frame frameRect: NSRect, onClick: @escaping () -> Void, onDrop: @escaping (URL) -> Void) {
        self.onClick = onClick
        self.onDrop = onDrop
        super.init(frame: frameRect)
        registerForDraggedTypes([.fileURL])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func mouseDown(with event: NSEvent) {
        onClick()
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard firstSupportedURL(from: sender.draggingPasteboard) != nil else {
            return []
        }

        isDragTargeted = true
        return .copy
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        isDragTargeted = false
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        defer { isDragTargeted = false }

        guard let url = firstSupportedURL(from: sender.draggingPasteboard) else {
            return false
        }

        onDrop(url)
        return true
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let symbolName = isDragTargeted ? "arrow.down.doc.fill" : "sparkles.rectangle.stack"
        let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Oodi Pop")?
            .withSymbolConfiguration(config)

        if isDragTargeted {
            NSColor.controlAccentColor.withAlphaComponent(0.18).setFill()
            bounds.insetBy(dx: 3, dy: 3).fill()
        }

        image?.draw(
            in: bounds.insetBy(dx: 5, dy: 5),
            from: .zero,
            operation: .sourceOver,
            fraction: 1
        )
    }

    private func firstSupportedURL(from pasteboard: NSPasteboard) -> URL? {
        guard let urls = pasteboard.readObjects(forClasses: [NSURL.self]) as? [URL] else {
            return nil
        }

        return urls.first { OodiPopMediaKind(fileURL: $0) != nil }
    }
}
