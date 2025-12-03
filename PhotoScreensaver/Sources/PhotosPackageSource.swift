import Foundation

/// Photo source that reads directly from the Photos Library package
/// Located at ~/Pictures/Photos Library.photoslibrary/originals/
/// This bypasses PhotoKit and reads the actual image files
final class PhotosPackageSource: PhotoSource, Sendable {
    let sourceType: PhotoSourceType = .photosPackage

    /// Path to the Photos Library package
    private let photosLibraryPath: URL

    /// Path to the originals folder within the package
    private var originalsPath: URL {
        photosLibraryPath.appendingPathComponent("originals")
    }

    /// Hex subdirectory names (0-9, A-F)
    private let hexDirectories = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"]

    /// Maximum number of photos to load
    private let maxPhotos = 10000

    init() {
        // Default Photos Library location
        self.photosLibraryPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Pictures")
            .appendingPathComponent("Photos Library.photoslibrary")
    }

    func isAvailable() -> Bool {
        var isDirectory: ObjCBool = false

        // Check if the Photos Library package exists
        guard FileManager.default.fileExists(atPath: photosLibraryPath.path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            return false
        }

        // Check if the originals folder exists and is readable
        guard FileManager.default.fileExists(atPath: originalsPath.path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            return false
        }

        return FileManager.default.isReadableFile(atPath: originalsPath.path)
    }

    func loadPhotoURLs() -> [URL] {
        guard isAvailable() else { return [] }

        var imageURLs: [URL] = []

        // Scan each hex subdirectory (Photos Library structure: originals/<hex>/<subhash>/image.heic)
        for hexDir in hexDirectories {
            let hexPath = originalsPath.appendingPathComponent(hexDir)

            guard FileManager.default.fileExists(atPath: hexPath.path) else {
                continue
            }

            // Recursively scan for images (typically 2 levels: hex/subhash/file)
            let urls = scanDirectory(hexPath, maxDepth: 2)
            imageURLs.append(contentsOf: urls)

            if imageURLs.count >= maxPhotos {
                break
            }
        }

        return Array(imageURLs.prefix(maxPhotos)).shuffled()
    }

    /// Recursively scan a directory for image files
    private func scanDirectory(_ directory: URL, maxDepth: Int, currentDepth: Int = 0) -> [URL] {
        guard currentDepth <= maxDepth else { return [] }

        var imageURLs: [URL] = []

        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            )

            for url in contents {
                var isDirectory: ObjCBool = false
                if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) {
                    if isDirectory.boolValue {
                        let subURLs = scanDirectory(url, maxDepth: maxDepth, currentDepth: currentDepth + 1)
                        imageURLs.append(contentsOf: subURLs)
                    } else if SupportedImageExtensions.isSupported(url) {
                        imageURLs.append(url)
                    }
                }

                if imageURLs.count >= maxPhotos {
                    break
                }
            }
        } catch {
            NSLog("PhotosPackageSource: Failed to read directory \(directory.lastPathComponent): \(error.localizedDescription)")
        }

        return imageURLs
    }
}
