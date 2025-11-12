# Implementation Details

## Project Overview

This macOS screensaver displays photos from the user's Photos library with smooth transitions and automatic rotation. It's built using modern Swift and Apple's ScreenSaver and PhotoKit frameworks.

## Architecture

### Core Components

1. **PhotoScreensaverView** (Main Class)
   - Inherits from `ScreenSaverView`
   - Manages the entire screensaver lifecycle
   - Coordinates photo loading, display, and rotation

2. **Image Display**
   - `NSImageView` for rendering photos
   - Aspect-fit scaling to maintain photo proportions
   - Black background for letterboxing/pillarboxing

3. **Photo Management**
   - Uses `PHCachingImageManager` for efficient image loading
   - Fetches images from Photos library using PhotoKit
   - Maintains array of `PHAsset` objects

4. **Rotation System**
   - `Timer` based rotation (every 5 seconds by default)
   - Sequential photo display with wrap-around
   - Smooth fade transitions using `NSAnimationContext`

## Key Features

### Photos Library Integration

The screensaver uses PhotoKit to access the Photos library:

```swift
PHPhotoLibrary.authorizationStatus(for: .readWrite)
PHPhotoLibrary.requestAuthorization(for: .readWrite)
```

- Uses `.readWrite` access level (required to read photos - no `.readOnly` option exists)
- `PHAccessLevel` only has two cases: `.addOnly` (write-only) and `.readWrite` (read/write)
- Handles all authorization states: authorized, limited, denied, restricted, notDetermined
- Provides clear user feedback for each state

### Photo Loading

Fetches all image assets from the library:

```swift
let fetchOptions = PHFetchOptions()
fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
```

- Filters for images only (excludes videos)
- Sorts by creation date (newest first)
- Efficiently enumerates results

### Image Rendering

Requests high-quality images with appropriate sizing:

```swift
let scale = window?.backingScaleFactor ?? NSScreen.main?.backingScaleFactor ?? 2.0
let targetSize = CGSize(width: bounds.width * scale, height: bounds.height * scale)
options.deliveryMode = .highQualityFormat
options.isNetworkAccessAllowed = true
```

- Uses dynamic backing scale factor for proper Retina and non-Retina display support
- Falls back to 2.0x if scale factor unavailable
- Allows network access for iCloud photos
- Asynchronous loading for smooth performance

### Smooth Transitions

Implements fade-out/fade-in transitions:

```swift
NSAnimationContext.runAnimationGroup { context in
    context.duration = 0.5
    self.imageView.animator().alphaValue = 0.0
} completionHandler: {
    self.imageView.image = image
    NSAnimationContext.runAnimationGroup { context in
        context.duration = 0.5
        self.imageView.animator().alphaValue = 1.0
    }
}
```

- 0.5 second fade-out
- Image swap during black screen
- 0.5 second fade-in
- Total transition: 1 second

## Error Handling

### No Photos Access

Displays a clear message if Photos access is denied:
- White text on black background
- Instructions to grant access in System Settings
- Centered, readable font

### No Photos Found

Shows helpful message if library is empty:
- Instructs user to add photos to Photos library
- Same styling as access denied message

## Memory Management

- Uses `weak self` in closures to prevent retain cycles
- Invalidates timer in `deinit`
- Efficient image caching via `PHCachingImageManager`
- Asynchronous operations on main queue for UI updates

## Performance Considerations

1. **Lazy Loading**: Photos loaded on-demand
2. **Caching**: PHCachingImageManager handles image cache
3. **Appropriate Sizing**: Requests 2x screen size (not full resolution)
4. **Async Operations**: All PhotoKit operations are asynchronous
5. **Timer-Based**: Uses system timer (not animation loop) for efficiency

## Customization Points

Users can easily modify:

1. **Rotation Interval**
   ```swift
   private let rotationInterval: TimeInterval = 5.0
   ```

2. **Transition Duration**
   ```swift
   context.duration = 0.5  // Change fade speed
   ```

3. **Image Resolution**
   ```swift
   let targetSize = CGSize(width: bounds.width * 2, height: bounds.height * 2)
   ```

4. **Photo Ordering**
   ```swift
   fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
   ```

## macOS Compatibility

- **Minimum**: macOS 13.0 (Ventura)
- **Target Framework**: ScreenSaver.framework
- **Language**: Swift 5.0
- **Architecture**: Universal (Intel + Apple Silicon)

## Privacy & Security

- Read-only Photos access (no modifications)
- Local processing only (no network transmission)
- Clear permission requests with usage descriptions
- Respects system privacy settings

## Known Limitations

1. **iCloud Photos**: May have delay loading from iCloud
2. **Large Libraries**: Initial load might take a moment
3. **Preview Mode**: Fully functional in preview (not simplified)
4. **Configuration**: No configuration sheet (future enhancement)

## Future Enhancements

Potential improvements:
- Configuration sheet for rotation speed, transition type
- Photo filtering (albums, favorites, date range)
- Ken Burns effect (pan and zoom)
- Multiple images in collage
- EXIF data display (date, location, camera)
- Shuffle/randomize option
- Smart albums support

## Testing Recommendations

When testing on macOS:

1. Test with empty Photos library
2. Test with denied Photos access
3. Test with limited Photos access (iOS-style)
4. Test with large library (1000+ photos)
5. Test with iCloud Photos enabled
6. Test in preview mode
7. Test in full-screen mode
8. Monitor memory usage over extended period
9. Test on both Retina and non-Retina displays
10. Test on Intel and Apple Silicon Macs

## Debugging Tips

1. Check Console.app for screensaver logs
2. Verify Photos permissions in System Settings
3. Ensure Photos library is not corrupted
4. Test with System Screen Saver picker
5. Check that bundle is in correct location
6. Verify Info.plist is valid
7. Ensure code signature (if required)

## Building from Source

Standard Xcode build process:
1. Open PhotoScreensaver.xcodeproj
2. Select PhotoScreensaver scheme
3. Build (⌘B)
4. Product installs to ~/Library/Screen Savers/

No external dependencies required.
