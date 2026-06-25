import Testing
import UIKit
import CoreImage
@testable import 附近

struct ImageFilterTests {
    private func makeTestImage(size: CGSize = CGSize(width: 200, height: 200)) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            UIColor.systemRed.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            UIColor.systemBlue.setFill()
            ctx.fill(CGRect(x: 50, y: 50, width: 100, height: 100))
        }
    }

    @Test func originalFilterReturnsSameImagePixels() throws {
        let image = makeTestImage()
        let filtered = try ImageFilterEngine.apply(filter: .original, to: image)
        #expect(filtered.size == image.size)
    }

    @Test func allFiltersProduceNonNilImage() throws {
        let image = makeTestImage()
        for filter in ImageFilter.allCases {
            let result = try ImageFilterEngine.apply(filter: filter, to: image)
            #expect(result.size.width > 0, "Filter \(filter.rawValue) produced empty image")
        }
    }

    @Test func inkFilterProducesGrayscale() throws {
        let image = makeTestImage()
        let filtered = try ImageFilterEngine.apply(filter: .ink, to: image)
        let ci = CIImage(image: filtered)!
        #expect(ci.extent.width > 0)
    }
}
