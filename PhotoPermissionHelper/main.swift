import Cocoa
import Photos

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var statusLabel: NSTextField!
    var openFDAButton: NSButton!
    var revealButton: NSButton!
    var requestPhotosButton: NSButton!
    var quitButton: NSButton!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Request Photos authorization on launch (triggers system dialog)
        requestPhotosAuthorization()

        // Create the window
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 380),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Photo Screensaver Setup"
        window.center()

        let contentView = NSView(frame: window.contentView!.bounds)
        contentView.autoresizingMask = [.width, .height]
        window.contentView = contentView

        // Title label
        let titleLabel = NSTextField(frame: NSRect(x: 20, y: 330, width: 460, height: 30))
        titleLabel.stringValue = "Photo Screensaver Setup"
        titleLabel.font = NSFont.boldSystemFont(ofSize: 20)
        titleLabel.isBordered = false
        titleLabel.isEditable = false
        titleLabel.backgroundColor = .clear
        titleLabel.alignment = .center
        contentView.addSubview(titleLabel)

        // Instructions
        let instructionsLabel = NSTextField(frame: NSRect(x: 20, y: 170, width: 460, height: 150))
        instructionsLabel.stringValue = """
        Option 1: Grant Full Disk Access (recommended)
        This allows the screensaver to read photos directly from your Photos Library.

        Steps:
        1. Click "Open Full Disk Access Settings" below
        2. Click the + button in the settings window
        3. Press Cmd+Shift+G and paste:
           /System/Library/Frameworks/ScreenSaver.framework/PlugIns/
        4. Select "legacyScreenSaver.appex" and click Open
        5. Restart System Settings and select the screensaver
        """
        instructionsLabel.font = NSFont.systemFont(ofSize: 13)
        instructionsLabel.isBordered = false
        instructionsLabel.isEditable = false
        instructionsLabel.backgroundColor = .clear
        instructionsLabel.alignment = .left
        instructionsLabel.lineBreakMode = .byWordWrapping
        instructionsLabel.maximumNumberOfLines = 0
        contentView.addSubview(instructionsLabel)

        // Open Full Disk Access button
        openFDAButton = NSButton(frame: NSRect(x: 50, y: 130, width: 250, height: 32))
        openFDAButton.title = "Open Full Disk Access Settings"
        openFDAButton.bezelStyle = .rounded
        openFDAButton.target = self
        openFDAButton.action = #selector(openFullDiskAccessSettings)
        contentView.addSubview(openFDAButton)

        // Reveal in Finder button
        revealButton = NSButton(frame: NSRect(x: 310, y: 130, width: 140, height: 32))
        revealButton.title = "Reveal in Finder"
        revealButton.bezelStyle = .rounded
        revealButton.target = self
        revealButton.action = #selector(revealScreenSaverInFinder)
        contentView.addSubview(revealButton)

        // Option 2 label
        let option2Label = NSTextField(frame: NSRect(x: 20, y: 85, width: 460, height: 35))
        option2Label.stringValue = "Option 2: Grant Photos access to this helper app\n(May work on some systems)"
        option2Label.font = NSFont.systemFont(ofSize: 12)
        option2Label.isBordered = false
        option2Label.isEditable = false
        option2Label.backgroundColor = .clear
        option2Label.textColor = .secondaryLabelColor
        option2Label.alignment = .center
        contentView.addSubview(option2Label)

        // Request Photos Access button
        requestPhotosButton = NSButton(frame: NSRect(x: 150, y: 50, width: 200, height: 32))
        requestPhotosButton.title = "Request Photos Access"
        requestPhotosButton.bezelStyle = .rounded
        requestPhotosButton.target = self
        requestPhotosButton.action = #selector(requestPhotosAccess)
        contentView.addSubview(requestPhotosButton)

        // Status label
        statusLabel = NSTextField(frame: NSRect(x: 20, y: 20, width: 460, height: 25))
        statusLabel.font = NSFont.systemFont(ofSize: 12)
        statusLabel.isBordered = false
        statusLabel.isEditable = false
        statusLabel.backgroundColor = .clear
        statusLabel.alignment = .center
        statusLabel.textColor = .secondaryLabelColor
        updatePhotosStatus()
        contentView.addSubview(statusLabel)

        // Quit button
        quitButton = NSButton(frame: NSRect(x: 400, y: 330, width: 80, height: 32))
        quitButton.title = "Quit"
        quitButton.bezelStyle = .rounded
        quitButton.target = self
        quitButton.action = #selector(quitApp)
        contentView.addSubview(quitButton)

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func requestPhotosAuthorization() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
            DispatchQueue.main.async {
                self?.updatePhotosStatus()
            }
        }
    }

    func updatePhotosStatus() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .authorized:
            statusLabel.stringValue = "✓ Photos access granted"
            statusLabel.textColor = .systemGreen
        case .limited:
            statusLabel.stringValue = "✓ Photos access granted (limited)"
            statusLabel.textColor = .systemGreen
        case .denied, .restricted:
            statusLabel.stringValue = "✗ Photos access denied - use Full Disk Access instead"
            statusLabel.textColor = .systemOrange
        case .notDetermined:
            statusLabel.stringValue = "Photos access not yet requested"
            statusLabel.textColor = .secondaryLabelColor
        @unknown default:
            statusLabel.stringValue = "Unknown Photos authorization status"
            statusLabel.textColor = .secondaryLabelColor
        }
    }

    @objc func openFullDiskAccessSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc func revealScreenSaverInFinder() {
        let path = "/System/Library/Frameworks/ScreenSaver.framework/PlugIns/legacyScreenSaver.appex"
        let url = URL(fileURLWithPath: path)
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    @objc func requestPhotosAccess() {
        requestPhotosAuthorization()
    }

    @objc func quitApp() {
        NSApp.terminate(nil)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

// Create and run the application
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
