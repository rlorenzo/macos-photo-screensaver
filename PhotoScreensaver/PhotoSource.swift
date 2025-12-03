import Foundation

/// Represents the type/source of photos
enum PhotoSourceType: String {
    case photoKit = "Photos Library"
    case photosPackage = "Photos Library Files"
    case picturesFolder = "Pictures Folder"
    case secondaryLocations = "Other Locations"
}

/// Protocol for all photo sources
protocol PhotoSource {
    /// The type of this photo source
    var sourceType: PhotoSourceType { get }

    /// Check if this source is available (e.g., folder exists, permission granted)
    func isAvailable() -> Bool

    /// Load photo URLs from this source
    /// - Returns: Array of file URLs pointing to images
    func loadPhotoURLs() -> [URL]
}

/// Supported image file extensions
enum SupportedImageExtensions {
    static let all: Set<String> = ["heic", "jpeg", "jpg", "png", "gif", "tiff", "tif", "bmp"]

    static func isSupported(_ url: URL) -> Bool {
        all.contains(url.pathExtension.lowercased())
    }
}
