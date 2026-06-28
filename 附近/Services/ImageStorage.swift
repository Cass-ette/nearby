import Foundation
import SwiftUI
import UIKit
import ImageIO

enum ImageStorage {
    static func resize(image: UIImage, maxLongEdge: CGFloat) throws -> UIImage {
        let size = image.size
        let longEdge = max(size.width, size.height)
        guard longEdge > maxLongEdge else { return image }
        let scale = maxLongEdge / longEdge
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    static func encodeJPEG(_ image: UIImage, quality: CGFloat) throws -> Data {
        guard let data = image.jpegData(compressionQuality: quality) else {
            throw ImageStorageError.encodingFailed
        }
        return data
    }

    static func makeThumbnail(_ image: UIImage, longEdge: CGFloat = 400, quality: CGFloat = 0.7) throws -> Data {
        let resized = try resize(image: image, maxLongEdge: longEdge)
        return try encodeJPEG(resized, quality: quality)
    }
}

enum ImageStorageError: Error {
    case encodingFailed
}

enum ImageDecodeCache {
    nonisolated(unsafe) private static let cache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 120
        cache.totalCostLimit = 36 * 1024 * 1024
        return cache
    }()

    static func image(from data: Data) -> UIImage? {
        let key = cacheKey(for: data)
        if let cached = cache.object(forKey: key) {
            return cached
        }
        guard let image = UIImage(data: data) else {
            return nil
        }
        cache.setObject(image, forKey: key, cost: data.count)
        return image
    }

    static func cachedImage(from data: Data) -> UIImage? {
        cache.object(forKey: cacheKey(for: data))
    }

    private static func cacheKey(for data: Data) -> NSString {
        "\(data.count)-\(data.hashValue)" as NSString
    }
}

struct AsyncDecodedImage<Content: View, Placeholder: View>: View {
    let data: Data?
    @ViewBuilder var content: (UIImage) -> Content
    @ViewBuilder var placeholder: () -> Placeholder

    @State private var image: UIImage?
    @State private var cacheKey = ""

    var body: some View {
        Group {
            if let image {
                content(image)
            } else {
                placeholder()
            }
        }
        .task(id: data?.hashValue) {
            guard let data else {
                image = nil
                cacheKey = ""
                return
            }

            let newKey = "\(data.count)-\(data.hashValue)"
            if cacheKey == newKey, image != nil {
                return
            }

            if let cached = ImageDecodeCache.cachedImage(from: data) {
                cacheKey = newKey
                image = cached
                return
            }

            let decoded = await Task.detached(priority: .utility) {
                ImageDecodeCache.image(from: data)
            }.value

            cacheKey = newKey
            image = decoded
        }
    }
}
