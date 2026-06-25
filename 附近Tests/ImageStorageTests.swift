import Testing
import UIKit
@testable import 附近

struct ImageStorageTests {
    private func makeImage(_ size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            UIColor.systemGreen.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
    }

    @Test func resizeCapsLongEdge() throws {
        let big = makeImage(CGSize(width: 4000, height: 3000))
        let resized = try ImageStorage.resize(image: big, maxLongEdge: 2400)
        #expect(max(resized.size.width, resized.size.height) == 2400, "Long edge should be capped at 2400")
    }

    @Test func resizeKeepsSmallImage() throws {
        let small = makeImage(CGSize(width: 800, height: 600))
        let resized = try ImageStorage.resize(image: small, maxLongEdge: 2400)
        #expect(resized.size.width == 800)
    }

    @Test func encodeProducesUnderBudget() throws {
        let image = makeImage(CGSize(width: 2400, height: 1800))
        let data = try ImageStorage.encodeJPEG(image, quality: 0.82)
        #expect(data.count < 1_500_000, "Expected < 1.5MB for solid-color JPEG, got \(data.count) bytes")
    }

    @Test func thumbnailIsSmallerThanFull() throws {
        let image = makeImage(CGSize(width: 2400, height: 1800))
        let full = try ImageStorage.encodeJPEG(image, quality: 0.82)
        let thumb = try ImageStorage.makeThumbnail(image, longEdge: 400, quality: 0.7)
        #expect(thumb.count < full.count / 4, "Thumbnail should be significantly smaller than full")
    }
}
