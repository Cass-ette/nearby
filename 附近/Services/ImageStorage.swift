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
