import ScreenSaver
import Photos
import Cocoa

@MainActor
class PhotoScreensaverView: ScreenSaverView {
    // MARK: - Properties

    private var imageView: NSImageView!
    private var messageView: NSTextField?

    /// Photo source manager handles the cascade of sources
    private let sourceManager = PhotoSourceManager()

    /// Image loader handles loading from both URLs and PHAssets
    private var imageLoader: ImageLoader!

    /// URLs of photos (when using file-based sources)
    private var photoURLs: [URL] = []

    /// PHAssets (when using PhotoKit)
    private var photoAssets: [PHAsset] = []

    /// Current photo index
    private var currentPhotoIndex: Int = 0

    /// Timer for rotating photos
    nonisolated(unsafe) private var rotationTimer: Timer?

    /// Rotation interval in seconds
    private let rotationInterval: TimeInterval = 5.0

    /// Fade transition duration
    private let fadeTransitionDuration: TimeInterval = 0.5

    // MARK: - Initialization

    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    deinit {
        rotationTimer?.invalidate()
    }

    // MARK: - Setup

    private func setup() {
        // Set animation time interval
        animationTimeInterval = 1.0 / 30.0

        // Setup image view
        imageView = NSImageView(frame: bounds)
        imageView.autoresizingMask = [.width, .height]
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.imageAlignment = .alignCenter
        imageView.wantsLayer = true
        imageView.layer?.backgroundColor = NSColor.black.cgColor
        addSubview(imageView)

        // Initialize image loader
        imageLoader = ImageLoader()

        // Load photos asynchronously to avoid blocking main thread
        loadPhotosAsync()
    }

    // MARK: - Photo Loading

    private func loadPhotosAsync() {
        // Show loading state initially
        showLoadingMessage()

        // Run expensive file system scanning on background thread
        Task.detached { [sourceManager] in
            let result = sourceManager.loadPhotos()

            await MainActor.run { [weak self] in
                self?.handlePhotosLoaded(result)
            }
        }
    }

    private func handlePhotosLoaded(_ result: PhotoLoadResult) {
        // Remove loading message
        messageView?.removeFromSuperview()
        messageView = nil

        if result.hasPhotos {
            photoURLs = result.urls
            photoAssets = result.assets
            NSLog("PhotoScreensaver: Loaded \(result.count) photos from \(result.source?.rawValue ?? "unknown")")
            startRotation()
        } else {
            showNoPhotosMessage()
        }
    }

    private func showLoadingMessage() {
        messageView?.removeFromSuperview()

        let fontSize: CGFloat = bounds.width < 400 ? 14 : 18
        let textField = NSTextField(frame: bounds.insetBy(dx: 20, dy: 20))
        textField.stringValue = "Loading photos..."
        textField.alignment = .center
        textField.font = NSFont.systemFont(ofSize: fontSize)
        textField.textColor = .white
        textField.backgroundColor = .clear
        textField.isBezeled = false
        textField.isEditable = false
        textField.isSelectable = false
        textField.autoresizingMask = [.width, .height]
        addSubview(textField)
        messageView = textField
    }

    private func showNoPhotosMessage() {
        // Remove previous message if it exists
        messageView?.removeFromSuperview()

        // Scale font size based on view size (smaller in preview)
        let fontSize: CGFloat = bounds.width < 400 ? 24 : 32

        // Message label - centered in view
        let textField = NSTextField(frame: bounds.insetBy(dx: 20, dy: 20))
        textField.stringValue = PhotoSourceManager.noPhotosGuidanceMessage()
        textField.alignment = .center
        textField.textColor = .white
        textField.backgroundColor = .clear
        textField.isBordered = false
        textField.isEditable = false
        textField.font = NSFont.systemFont(ofSize: fontSize, weight: .medium)
        textField.autoresizingMask = [.width, .height]
        textField.maximumNumberOfLines = 0
        textField.lineBreakMode = .byWordWrapping
        messageView = textField
        addSubview(textField)
    }

    // MARK: - Photo Rotation

    private func startRotation() {
        // Display first photo immediately
        displayCurrentPhoto()

        // Setup timer for rotation
        rotationTimer = Timer.scheduledTimer(withTimeInterval: rotationInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.rotateToNextPhoto()
            }
        }
    }

    private func rotateToNextPhoto() {
        let totalCount = max(photoURLs.count, photoAssets.count)
        guard totalCount > 0 else { return }

        currentPhotoIndex = (currentPhotoIndex + 1) % totalCount
        displayCurrentPhoto()
    }

    private func displayCurrentPhoto() {
        let totalCount = max(photoURLs.count, photoAssets.count)
        guard totalCount > 0, currentPhotoIndex < totalCount else { return }

        // Calculate target size
        let scale = window?.backingScaleFactor ?? NSScreen.main?.backingScaleFactor ?? 2.0
        let targetSize = CGSize(width: bounds.width * scale, height: bounds.height * scale)

        // Load based on source type
        if !photoAssets.isEmpty {
            loadFromAsset(at: currentPhotoIndex, targetSize: targetSize)
        } else if !photoURLs.isEmpty {
            loadFromURL(at: currentPhotoIndex, targetSize: targetSize)
        }
    }

    private func loadFromAsset(at index: Int, targetSize: CGSize) {
        guard index < photoAssets.count else { return }
        let asset = photoAssets[index]

        imageLoader.loadImage(from: asset, targetSize: targetSize) { [weak self] image in
            if let image = image {
                self?.displayImageWithFade(image)
            } else {
                // Skip to next photo on failure
                NSLog("PhotoScreensaver: Failed to load asset at index \(index)")
                self?.rotateToNextPhoto()
            }
        }
    }

    private func loadFromURL(at index: Int, targetSize: CGSize) {
        guard index < photoURLs.count else { return }
        let url = photoURLs[index]

        imageLoader.loadImage(from: url, targetSize: targetSize) { [weak self] image in
            if let image = image {
                self?.displayImageWithFade(image)
            } else {
                // Skip to next photo on failure
                NSLog("PhotoScreensaver: Failed to load image at \(url.path)")
                self?.rotateToNextPhoto()
            }
        }
    }

    private func displayImageWithFade(_ image: NSImage) {
        let fadeDuration = fadeTransitionDuration
        let imageViewRef = imageView!

        NSAnimationContext.runAnimationGroup { context in
            context.duration = fadeDuration
            imageViewRef.animator().alphaValue = 0.0
        } completionHandler: {
            Task { @MainActor in
                imageViewRef.image = image
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = fadeDuration
                    imageViewRef.animator().alphaValue = 1.0
                }
            }
        }
    }

    // MARK: - ScreenSaverView Overrides

    override func startAnimation() {
        super.startAnimation()
        let hasPhotos = !photoURLs.isEmpty || !photoAssets.isEmpty
        if hasPhotos {
            if rotationTimer == nil {
                startRotation()
            } else {
                rotationTimer?.fire()
            }
        }
    }

    override func stopAnimation() {
        super.stopAnimation()
        rotationTimer?.invalidate()
        rotationTimer = nil
    }

    override func animateOneFrame() {
        // Animation handled by timer
    }

    override var hasConfigureSheet: Bool {
        return false
    }
}
