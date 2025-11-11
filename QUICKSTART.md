# Quick Start Guide

## Building and Installing the PhotoScreensaver

### Step 1: Build the Project

```bash
# Open the project in Xcode
open PhotoScreensaver.xcodeproj

# Or build from command line
xcodebuild -project PhotoScreensaver.xcodeproj -scheme PhotoScreensaver -configuration Release
```

### Step 2: Install the Screensaver

The screensaver will be automatically installed to:
```
~/Library/Screen Savers/PhotoScreensaver.saver
```

### Step 3: Activate the Screensaver

1. Open **System Settings** (or System Preferences on older macOS)
2. Navigate to **Screen Saver** (or Desktop & Screen Saver)
3. Look for **PhotoScreensaver** in the list on the left
4. Select it and adjust preview settings as needed
5. Click **Screen Saver Options** if you want to configure timing

### Step 4: Grant Photos Access

When the screensaver first runs:

1. macOS will display a permission dialog
2. Click **OK** or **Allow** to grant Photos library access
3. The screensaver will then start displaying your photos

**Manual Permission Grant:**

If you miss the dialog or want to check permissions:

1. Open **System Settings**
2. Go to **Privacy & Security** → **Photos**
3. Find and enable the screensaver in the list

### Step 5: Test the Screensaver

- Click **Preview** in Screen Saver settings to test
- Or wait for your configured idle time
- Press any key or move the mouse to exit

## Verifying Installation

Check if the screensaver is properly installed:

```bash
ls -la ~/Library/Screen\ Savers/PhotoScreensaver.saver
```

You should see the bundle with a recent timestamp.

## Viewing Logs (for Troubleshooting)

If the screensaver isn't working:

```bash
# Open Console.app and filter for "PhotoScreensaver" or "ScreenSaver"
open /System/Applications/Utilities/Console.app
```

Look for error messages related to Photos access or bundle loading.

## Uninstalling

To remove the screensaver:

```bash
rm -rf ~/Library/Screen\ Savers/PhotoScreensaver.saver
```

Then restart System Settings or log out/in.
