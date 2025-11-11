import ScreenSaver
import Photos
import Cocoa

class PhotoScreensaverView: ScreenSaverView {
    
    // MARK: - Properties

    private var imageView: NSImageView!
    private var photos: [PHAsset] = []
    private var currentPhotoIndex: Int = 0
    private var rotationTimer: Timer?
    private let rotationInterval: TimeInterval = 5.0 // Rotate every 5 seconds
    private let fadeTransitionDuration: TimeInterval = 0.5
    private var imageManager: PHCachingImageManager!
    private var isAuthorized: Bool = false
    private var messageView: NSTextField?
    
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
        imageManager?.stopCachingImagesForAllAssets()
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
        
        // Initialize image manager
        imageManager = PHCachingImageManager()
        
        // Request photo library access
        requestPhotoLibraryAccess()
    }
    
    // MARK: - Photo Library Access
    
    private func requestPhotoLibraryAccess() {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)

        switch status {
        case .authorized, .limited:
            DispatchQueue.main.async { [weak self] in
                self?.isAuthorized = true
                self?.loadPhotos()
            }
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { [weak self] newStatus in
                DispatchQueue.main.async {
                    if newStatus == .authorized || newStatus == .limited {
                        self?.isAuthorized = true
                        self?.loadPhotos()
                    } else {
                        self?.showAccessDeniedMessage()
                    }
                }
            }
        case .denied, .restricted:
            showAccessDeniedMessage()
        @unknown default:
            showAccessDeniedMessage()
        }
    }
    
    private func showAccessDeniedMessage() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // Remove previous message if it exists
            self.messageView?.removeFromSuperview()

            let textField = NSTextField(frame: self.bounds.insetBy(dx: 40, dy: 40))
            textField.stringValue = "Photo Library Access Required\n\nPlease grant access to Photos in System Settings > Privacy & Security > Photos"
            textField.alignment = .center
            textField.textColor = .white
            textField.backgroundColor = .clear
            textField.isBordered = false
            textField.isEditable = false
            textField.font = NSFont.systemFont(ofSize: 24, weight: .medium)
            textField.autoresizingMask = [.width, .height]
            self.messageView = textField
            self.addSubview(textField)
        }
    }
    
    // MARK: - Photo Loading
    
    private func loadPhotos() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        
        let fetchResult = PHAsset.fetchAssets(with: fetchOptions)
        
        photos.removeAll()
        fetchResult.enumerateObjects { [weak self] asset, _, _ in
            self?.photos.append(asset)
        }
        
        if !photos.isEmpty {
            startRotation()
        } else {
            showNoPhotosMessage()
        }
    }
    
    private func showNoPhotosMessage() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // Remove previous message if it exists
            self.messageView?.removeFromSuperview()

            let textField = NSTextField(frame: self.bounds.insetBy(dx: 40, dy: 40))
            textField.stringValue = "No Photos Found\n\nAdd photos to your Photos library to use this screensaver"
            textField.alignment = .center
            textField.textColor = .white
            textField.backgroundColor = .clear
            textField.isBordered = false
            textField.isEditable = false
            textField.font = NSFont.systemFont(ofSize: 24, weight: .medium)
            textField.autoresizingMask = [.width, .height]
            self.messageView = textField
            self.addSubview(textField)
        }
    }
    
    // MARK: - Photo Rotation
    
    private func startRotation() {
        // Display first photo immediately
        displayCurrentPhoto()

        // Setup timer for rotation using block-based API to avoid retain cycles
        rotationTimer = Timer.scheduledTimer(withTimeInterval: rotationInterval, repeats: true) { [weak self] _ in
            self?.rotateToNextPhoto()
        }
    }

    private func rotateToNextPhoto() {
        guard !photos.isEmpty else { return }

        currentPhotoIndex = (currentPhotoIndex + 1) % photos.count
        displayCurrentPhoto()
    }
    
    private func displayCurrentPhoto() {
        guard !photos.isEmpty, currentPhotoIndex < photos.count else { return }

        let asset = photos[currentPhotoIndex]

        // Use actual backing scale factor instead of hardcoded 2x
        let scale = window?.backingScaleFactor ?? NSScreen.main?.backingScaleFactor ?? 2.0
        let targetSize = CGSize(width: bounds.width * scale, height: bounds.height * scale)

        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false

        imageManager.requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFit,
            options: options
        ) { [weak self] image, info in
            guard let self = self else { return }

            if let image = image {
                DispatchQueue.main.async {
                    // Add fade transition
                    NSAnimationContext.runAnimationGroup { context in
                        context.duration = self.fadeTransitionDuration
                        self.imageView.animator().alphaValue = 0.0
                    } completionHandler: {
                        self.imageView.image = image
                        NSAnimationContext.runAnimationGroup { context in
                            context.duration = self.fadeTransitionDuration
                            self.imageView.animator().alphaValue = 1.0
                        }
                    }
                }
            } else if let error = info?[PHImageErrorKey] as? Error {
                // Log error and skip to next photo
                NSLog("PhotoScreensaver: Failed to load image: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.rotateToNextPhoto()
                }
            } else {
                // Image is nil but no error - might be cancelled or degraded
                NSLog("PhotoScreensaver: Image loading returned nil without error")
            }
        }
    }
    
    // MARK: - ScreenSaverView Overrides
    
    override func startAnimation() {
        super.startAnimation()
        if isAuthorized && !photos.isEmpty {
            rotationTimer?.fire()
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
