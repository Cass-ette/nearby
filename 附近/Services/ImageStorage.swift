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

@MainActor
enum ImageDecodeCache {
    private static let cache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 240
        cache.totalCostLimit = 80 * 1024 * 1024
        return cache
    }()

    static func image(from data: Data) -> UIImage? {
        let key = "\(data.count)-\(data.hashValue)" as NSString
        if let cached = cache.object(forKey: key) {
            return cached
        }
        guard let image = UIImage(data: data) else {
            return nil
        }
        cache.setObject(image, forKey: key, cost: data.count)
        return image
    }
}
