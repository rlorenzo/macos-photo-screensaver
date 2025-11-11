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

- macOS 13.0 (Ventura) or later
- Xcode 15.0 or later
- Access to Photos library

## Building

1. Open `PhotoScreensaver.xcodeproj` in Xcode
2. Select the "PhotoScreensaver" scheme
3. Build the project (⌘B)
4. The screensaver bundle will be built to `~/Library/Screen Savers/PhotoScreensaver.saver`

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

The first time the screensaver runs, macOS will prompt you to grant access to your Photos library. You can also manually grant access:

1. Open System Settings
2. Go to Privacy & Security > Photos
3. Enable access for "PhotoScreensaver"

## How It Works

The screensaver uses Apple's PhotoKit framework to:

1. Request authorization to access the Photos library
2. Fetch all image assets from the library
3. Display photos in full-screen with aspect-fit scaling
4. Automatically rotate to the next photo every 5 seconds
5. Use smooth fade transitions between photos

## Technical Details

- **Language**: Swift 5.0
- **Framework**: ScreenSaver, PhotoKit, Cocoa
- **Deployment Target**: macOS 13.0+
- **Photo Loading**: PHCachingImageManager for efficient image loading
- **Transitions**: NSAnimationContext for smooth fade effects
- **Timer**: Uses Timer for photo rotation with configurable interval

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

## Troubleshooting

### "No Photos Found" Message

- Ensure you have photos in your Photos library
- Check that the Photos app can access your library

### "Photo Library Access Required" Message

- Open System Settings > Privacy & Security > Photos
- Enable access for the screensaver
- Restart the screensaver preview

### Screensaver Not Appearing in System Settings

- Verify the `.saver` bundle is in `~/Library/Screen Savers/` or `/Library/Screen Savers/`
- Try logging out and back in
- Check Console.app for any error messages

## License

Copyright © 2025. All rights reserved.
