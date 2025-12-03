import Cocoa
import Photos
import UniformTypeIdentifiers

/// Unified image loader that handles both file URLs and PHAssets
@MainActor
class ImageLoader {
    /// Cache for loaded images (keyed by URL + size)
    private let cache = NSCache<NSString, NSImage>()

    init() {
        // Configure cache limits
        cache.countLimit = 50
        cache.totalCostLimit = 100 * 1024 * 1024 // 100 MB
    }

    /// Create a cache key that includes URL and size
    private func cacheKey(for url: URL, size: CGSize) -> NSString {
        "\(url.absoluteString)|\(Int(size.width))x\(Int(size.height))" as NSString
    }

    /// Load an image from a file URL
    /// - Parameters:
    ///   - url: File URL of the image
    ///   - targetSize: Desired size for the image
    ///   - completion: Callback with the loaded image or nil
    func loadImage(from url: URL, targetSize: CGSize, completion: @escaping @MainActor @Sendable (NSImage?) -> Void) {
        let key = cacheKey(for: url, size: targetSize)

        // Check cache first
        if let cached = cache.object(forKey: key) {
            completion(cached)
            return
        }

        // Load asynchronously using Task that maintains MainActor isolation
        Task {
            let image = await loadImageAsync(from: url, targetSize: targetSize)
            if let image = image {
                cache.setObject(image, forKey: key)
            }
            completion(image)
        }
    }

    /// Async helper to load image off main thread
    private func loadImageAsync(from url: URL, targetSize: CGSize) async -> NSImage? {
        // Do heavy CGImage work on background thread
        let cgImage = await Task.detached {
            Self.loadCGImageSync(from: url, targetSize: targetSize)
        }.value

        // Create NSImage on MainActor (AppKit requirement)
        guard let cgImage = cgImage else { return nil }
        return NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
    }

    /// Load an image from a PHAsset
    /// - Parameters:
    ///   - asset: PHAsset to load
    ///   - targetSize: Desired size for the image
    ///   - completion: Callback with the loaded image or nil
    nonisolated func loadImage(from asset: PHAsset, targetSize: CGSize, completion: @escaping @MainActor @Sendable (NSImage?) -> Void) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false

        PHCachingImageManager.default().requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFit,
            options: options
        ) { image, _ in
            Task { @MainActor in
                completion(image)
            }
        }
    }

    /// Synchronously load a CGImage from a file URL (thread-safe, uses CoreGraphics only)
    nonisolated private static func loadCGImageSync(from url: URL, targetSize: CGSize) -> CGImage? {
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            return nil
        }

        // Try to create a thumbnail at the target size (most efficient)
        let maxDimension = max(targetSize.width, targetSize.height)
        let thumbnailOptions: [CFString: Any] = [
            kCGImageSourceThumbnailMaxPixelSize: maxDimension,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true
        ]

        if let cgImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, thumbnailOptions as CFDictionary) {
            return cgImage
        }

        // Fallback: load full image and resize with CoreGraphics (thread-safe)
        guard let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            return nil
        }

        if let resized = resizeCGImage(cgImage, to: targetSize) {
            return resized
        }

        // Last resort: return full image without resizing
        return cgImage
    }

    /// Resize a CGImage using CoreGraphics (thread-safe)
    nonisolated private static func resizeCGImage(_ image: CGImage, to targetSize: CGSize) -> CGImage? {
        let originalWidth = CGFloat(image.width)
        let originalHeight = CGFloat(image.height)

        // Calculate scale to fit within target
        let widthRatio = targetSize.width / originalWidth
        let heightRatio = targetSize.height / originalHeight
        let scale = min(widthRatio, heightRatio, 1.0)

        if scale >= 1.0 {
            return image // No resize needed
        }

        let newWidth = Int(originalWidth * scale)
        let newHeight = Int(originalHeight * scale)

        guard let colorSpace = image.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                  data: nil,
                  width: newWidth,
                  height: newHeight,
                  bitsPerComponent: image.bitsPerComponent,
                  bytesPerRow: 0,
                  space: colorSpace,
                  bitmapInfo: image.bitmapInfo.rawValue
              ) else {
            return nil
        }

        context.interpolationQuality = .high
        context.draw(image, in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))

        return context.makeImage()
    }
}
