import Foundation
import Photos

/// Result of loading photos from sources
struct PhotoLoadResult {
    /// URLs of discovered photos (empty if using PhotoKit)
    let urls: [URL]

    /// PHAssets if loaded via PhotoKit (empty if using file-based sources)
    let assets: [PHAsset]

    /// The source that provided the photos
    let source: PhotoSourceType?

    /// Whether photos were found
    var hasPhotos: Bool {
        !urls.isEmpty || !assets.isEmpty
    }

    /// Total count of photos
    var count: Int {
        max(urls.count, assets.count)
    }

    /// Empty result
    static let empty = PhotoLoadResult(urls: [], assets: [], source: nil)
}

/// Manages the cascade of photo sources, trying each in order until photos are found
final class PhotoSourceManager: Sendable {
    /// The photo sources in priority order
    private let photoKitSource = PhotoKitSource()
    private let photosPackageSource = PhotosPackageSource()
    private let picturesFolderSource = FileSystemSource.picturesFolder()
    private let secondaryLocationsSource = FileSystemSource.secondaryLocations()

    /// Load photos using the cascade fallback strategy
    /// - Returns: PhotoLoadResult with photos and source information
    func loadPhotos() -> PhotoLoadResult {
        // Level 1: Try PhotoKit first (best experience when it works)
        if photoKitSource.isAvailable() {
            let assets = photoKitSource.loadAssets()
            if !assets.isEmpty {
                NSLog("PhotoSourceManager: Loaded \(assets.count) photos from PhotoKit")
                return PhotoLoadResult(urls: [], assets: assets, source: .photoKit)
            }
        }

        // Level 2: Try direct access to Photos Library package
        if photosPackageSource.isAvailable() {
            let urls = photosPackageSource.loadPhotoURLs()
            if !urls.isEmpty {
                NSLog("PhotoSourceManager: Loaded \(urls.count) photos from Photos Library package")
                return PhotoLoadResult(urls: urls, assets: [], source: .photosPackage)
            }
        }

        // Level 3: Try ~/Pictures folder
        if picturesFolderSource.isAvailable() {
            let urls = picturesFolderSource.loadPhotoURLs()
            if !urls.isEmpty {
                NSLog("PhotoSourceManager: Loaded \(urls.count) photos from Pictures folder")
                return PhotoLoadResult(urls: urls, assets: [], source: .picturesFolder)
            }
        }

        // Level 4: Try secondary locations (Desktop, Downloads)
        if secondaryLocationsSource.isAvailable() {
            let urls = secondaryLocationsSource.loadPhotoURLs()
            if !urls.isEmpty {
                NSLog("PhotoSourceManager: Loaded \(urls.count) photos from secondary locations")
                return PhotoLoadResult(urls: urls, assets: [], source: .secondaryLocations)
            }
        }

        // Level 5: No photos found
        NSLog("PhotoSourceManager: No photos found from any source")
        return .empty
    }

    /// Get the guidance message to show when no photos are found
    /// - Returns: User-friendly message with actionable instructions
    static func noPhotosGuidanceMessage() -> String {
        """
        No Photos Found

        Run PhotoPermissionHelper app to set up,
        or add photos to ~/Pictures folder.
        """
    }
}
