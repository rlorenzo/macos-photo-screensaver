import Foundation

/// Photo source that scans filesystem folders for image files
/// Can be configured with multiple paths and supports recursive scanning
final class FileSystemSource: PhotoSource, Sendable {
    let sourceType: PhotoSourceType

    /// Paths to scan for images
    private let paths: [URL]

    /// Maximum recursion depth (0 = top level only)
    private let maxDepth: Int

    /// Maximum number of photos to load
    private let maxPhotos: Int

    /// Initialize with paths and options
    /// - Parameters:
    ///   - sourceType: The type label for this source
    ///   - paths: Array of folder URLs to scan
    ///   - maxDepth: Maximum recursion depth (default: 5)
    ///   - maxPhotos: Maximum photos to return (default: 10000)
    init(sourceType: PhotoSourceType, paths: [URL], maxDepth: Int = 5, maxPhotos: Int = 10000) {
        self.sourceType = sourceType
        self.paths = paths
        self.maxDepth = maxDepth
        self.maxPhotos = maxPhotos
    }

    /// Convenience initializer for Pictures folder
    static func picturesFolder() -> FileSystemSource {
        let picturesPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Pictures")
        return FileSystemSource(sourceType: .picturesFolder, paths: [picturesPath])
    }

    /// Convenience initializer for secondary locations (Desktop, Downloads)
    static func secondaryLocations() -> FileSystemSource {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let paths = [
            home.appendingPathComponent("Desktop"),
            home.appendingPathComponent("Downloads")
        ]
        return FileSystemSource(sourceType: .secondaryLocations, paths: paths, maxDepth: 3)
    }

    func isAvailable() -> Bool {
        // Check if at least one path exists and is readable
        for path in paths {
            var isDirectory: ObjCBool = false
            if FileManager.default.fileExists(atPath: path.path, isDirectory: &isDirectory),
               isDirectory.boolValue,
               FileManager.default.isReadableFile(atPath: path.path) {
                return true
            }
        }
        return false
    }

    func loadPhotoURLs() -> [URL] {
        var imageURLs: [URL] = []

        for basePath in paths {
            guard FileManager.default.isReadableFile(atPath: basePath.path) else {
                continue
            }

            let urls = scanDirectory(basePath, currentDepth: 0)
            imageURLs.append(contentsOf: urls)

            if imageURLs.count >= maxPhotos {
                break
            }
        }

        // Shuffle for variety
        return Array(imageURLs.prefix(maxPhotos)).shuffled()
    }

    /// Recursively scan a directory for image files
    /// - Parameters:
    ///   - directory: Directory to scan
    ///   - currentDepth: Current recursion depth
    /// - Returns: Array of image file URLs
    private func scanDirectory(_ directory: URL, currentDepth: Int) -> [URL] {
        var imageURLs: [URL] = []

        guard currentDepth <= maxDepth else { return imageURLs }

        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.isRegularFileKey, .isDirectoryKey],
                options: [.skipsHiddenFiles]
            )

            for url in contents {
                // Skip .photoslibrary packages (handled by PhotosPackageSource)
                if url.pathExtension == "photoslibrary" {
                    continue
                }

                var isDirectory: ObjCBool = false
                if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) {
                    if isDirectory.boolValue {
                        // Recursively scan subdirectories
                        let subURLs = scanDirectory(url, currentDepth: currentDepth + 1)
                        imageURLs.append(contentsOf: subURLs)
                    } else if SupportedImageExtensions.isSupported(url) {
                        // Add image file
                        imageURLs.append(url)
                    }
                }

                // Early exit if we've found enough
                if imageURLs.count >= maxPhotos {
                    break
                }
            }
        } catch {
            NSLog("FileSystemSource: Failed to scan directory \(directory.path): \(error.localizedDescription)")
        }

        return imageURLs
    }
}
