# macOS Photo Screensaver

A simple macOS screensaver that displays photos from your Photos library with smooth transitions and automatic rotation.

## Features

- 🖼️ Displays photos from your macOS Photos library
- 🔄 Automatic photo rotation every 5 seconds
- ✨ Smooth fade transitions between photos
- 📐 Aspect-fit scaling for optimal photo display
- 🔒 Secure PhotoKit integration with proper permissions
- 🎨 Modern Swift implementation using ScreenSaver framework

## Requirements

- macOS 13.0 (Ventura) or later (for running the screensaver)
- Xcode 16.2 or later (for building with Swift 6.2)
- Access to Photos library

## Building

### Using the Build Script (Recommended)

The easiest way to build and install:

```bash
./build.sh                  # Build and install (Release)
./build.sh --debug          # Build and install (Debug)
./build.sh --build-only     # Build only, don't install
./build.sh --ci             # CI mode (non-interactive)
./build.sh --help           # Show help
```

### Using Xcode

1. Open `PhotoScreensaver.xcodeproj` in Xcode
2. Select the "PhotoScreensaver" scheme
3. Build the project (⌘B)
4. The screensaver bundle will be built to `build/PhotoScreensaver.saver`

## Installation

### From Xcode Build:

1. Build the project in Xcode
2. The screensaver is automatically installed to `~/Library/Screen Savers/`
3. Open System Settings > Screen Saver
4. Select "PhotoScreensaver" from the list
5. Grant Photos access when prompted

### Manual Installation:

1. Build the project
2. Locate the `PhotoScreensaver.saver` bundle in the build products
3. Double-click the bundle or copy it to:
   - `~/Library/Screen Savers/` (for current user only)
   - `/Library/Screen Savers/` (for all users, requires admin)
4. Open System Settings > Screen Saver
5. Select "PhotoScreensaver" from the list

## Granting Photo Access

Due to macOS security restrictions, third-party screensavers cannot directly request Photos library access. The screensaver uses a cascading fallback system to find photos automatically. For best results, see **Granting Full Disk Access** below.

## How It Works

The screensaver uses a cascading photo source system to find photos:

1. **PhotoKit** - Requests access to your Photos library (if permission granted)
2. **Photos Library Files** - Reads directly from `~/Pictures/Photos Library.photoslibrary/` (requires Full Disk Access)
3. **Pictures Folder** - Scans `~/Pictures/` for image files
4. **Other Locations** - Falls back to Desktop and Downloads folders

This design ensures the screensaver can display photos even when PhotoKit permissions aren't available (which is common for third-party screensavers on modern macOS).

## Technical Details

- **Language**: Swift 6.2
- **Framework**: ScreenSaver, PhotoKit, Cocoa
- **Deployment Target**: macOS 13.0+
- **Build Requirements**: Xcode 16.2+
- **Photo Sources**: Cascading system (PhotoKit, Photos Library files, Pictures folder, Desktop/Downloads)
- **Image Loading**: CGImageSource for thread-safe HEIC/JPEG/PNG loading
- **Caching**: NSCache with size-aware keys for efficient memory usage
- **Transitions**: NSAnimationContext for smooth fade effects
- **Timer**: Uses Timer for photo rotation with configurable interval
- **Concurrency**: Full Swift 6.2 concurrency compliance with @MainActor isolation

## Customization

You can customize the screensaver by modifying `PhotoScreensaverView.swift`:

- `rotationInterval`: Change photo rotation speed (default: 5.0 seconds)
- `targetSize`: Adjust photo resolution for different displays
- Transition duration: Modify the fade animation duration (default: 0.5 seconds)

## Privacy

This screensaver:
- Only requests read access to your Photos library
- Does not upload or transmit any photos
- Does not modify your photo library
- Runs entirely locally on your Mac

## Granting Full Disk Access

For the best experience (displaying photos from your Photos library), grant Full Disk Access:

1. Open **System Settings > Privacy & Security > Full Disk Access**
2. Click the **+** button
3. Navigate to `/System/Library/Frameworks/ScreenSaver.framework/PlugIns/legacyScreenSaver.appex`
   - Press `Cmd+Shift+G` in the file picker and paste the path above
4. Add `legacyScreenSaver.appex` to the list and enable it
5. Restart the screensaver preview

**Why is this needed?** Third-party screensavers run inside `legacyScreenSaver.appex`, which cannot request Photos permissions directly. Full Disk Access allows the screensaver to read photos from the Photos Library package.

## PhotoPermissionHelper App

The project includes a helper app that provides guidance for setting up permissions:

1. Build the **PhotoPermissionHelper** target in Xcode
2. Run the app
3. Use the buttons to:
   - **Open Full Disk Access Settings** - Opens the correct System Settings page
   - **Reveal in Finder** - Shows the `legacyScreenSaver.appex` file to add

## Troubleshooting

### "No Photos Found" Message

- Grant Full Disk Access to `legacyScreenSaver.appex` (see above)
- Ensure you have photos in your Photos library or Pictures folder
- Check that image files exist in `~/Pictures/`

### "Photo Library Access Required" Message

This message appears when PhotoKit access is denied. The screensaver will automatically try alternative sources:
- Grant Full Disk Access to read from the Photos Library package
- Or place photos directly in your `~/Pictures/` folder

### Screensaver Not Appearing in System Settings

- Verify the `.saver` bundle is in `~/Library/Screen Savers/` or `/Library/Screen Savers/`
- Try logging out and back in
- Check Console.app for any error messages

## License

MIT License - see [LICENSE](LICENSE) for details.
