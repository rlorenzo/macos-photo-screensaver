import Foundation
import Photos

/// Photo source that uses PhotoKit (PHPhotoLibrary) to access the Photos library
///
/// Note: Third-party screensavers run under legacyScreenSaver.appex and cannot
/// request PhotoKit authorization themselves. This source checks if authorization
/// was granted via other means, but the realistic fallback is file-based sources.
final class PhotoKitSource: PhotoSource, Sendable {
    let sourceType: PhotoSourceType = .photoKit

    func isAvailable() -> Bool {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        return status == .authorized || status == .limited
    }

    func loadPhotoURLs() -> [URL] {
        // PhotoKit uses PHAsset, not file URLs
        return []
    }

    /// Load PHAssets from the photo library
    func loadAssets() -> [PHAsset] {
        guard isAvailable() else { return [] }

        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)

        let fetchResult = PHAsset.fetchAssets(with: fetchOptions)

        var assets: [PHAsset] = []
        let maxCount = min(fetchResult.count, 10000)

        fetchResult.enumerateObjects { asset, index, stop in
            assets.append(asset)
            if index >= maxCount - 1 {
                stop.pointee = true
            }
        }

        return assets
    }
}
