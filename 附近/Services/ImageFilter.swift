import UIKit
import CoreImage

enum ImageFilter: String, CaseIterable, Identifiable {
    case original = "原图"
    case paper = "纸"
    case ink = "墨"
    case morning = "晨"
    case dusk = "暮"
    case mist = "雾"

    var id: String { rawValue }

    var localizedName: String {
        NSLocalizedString("filter.\(rawValue)", value: rawValue, comment: "")
    }
}

enum ImageFilterEngine {
    private static let context = CIContext(options: [.useSoftwareRenderer: false])

    static func apply(filter: ImageFilter, to image: UIImage) throws -> UIImage {
        guard let cgImage = image.cgImage else {
            throw ImageFilterError.invalidInput
        }
        let ci = CIImage(cgImage: cgImage)

        let output: CIImage
        switch filter {
        case .original:
            output = ci
        case .paper:
            let controls = ci.applyingFilter("CIColorControls", parameters: [
                kCIInputSaturationKey: 0.7,
                kCIInputBrightnessKey: 0.05,
            ])
            output = controls.applyingFilter("CIColorMatrix", parameters: [
                "inputRVector": CIVector(x: 1.05, y: 0, z: 0),
                "inputGVector": CIVector(x: 0, y: 1.0, z: 0),
                "inputBVector": CIVector(x: 0, y: 0, z: 0.9),
            ])
        case .ink:
            let mono = ci.applyingFilter("CIPhotoEffectMono")
            output = mono.applyingFilter("CIVignette", parameters: [
                "inputIntensity": 0.8,
                "inputRadius": 8.0,
            ])
        case .morning:
            let controls = ci.applyingFilter("CIColorControls", parameters: [
                kCIInputBrightnessKey: 0.08,
            ])
            output = controls.applyingFilter("CIColorMatrix", parameters: [
                "inputRVector": CIVector(x: 0.95, y: 0, z: 0),
                "inputGVector": CIVector(x: 0, y: 0.98, z: 0),
                "inputBVector": CIVector(x: 0, y: 0, z: 1.08),
            ])
        case .dusk:
            let controls = ci.applyingFilter("CIColorControls", parameters: [
                kCIInputBrightnessKey: -0.05,
                kCIInputSaturationKey: 0.9,
            ])
            output = controls.applyingFilter("CIColorMatrix", parameters: [
                "inputRVector": CIVector(x: 1.08, y: 0, z: 0),
                "inputGVector": CIVector(x: 0, y: 1.0, z: 0),
                "inputBVector": CIVector(x: 0, y: 0, z: 0.85),
            ])
        case .mist:
            let controls = ci.applyingFilter("CIColorControls", parameters: [
                kCIInputContrastKey: 0.85,
                kCIInputSaturationKey: 0.85,
            ])
            output = controls.applyingFilter("CIColorMatrix", parameters: [
                "inputRVector": CIVector(x: 1.0, y: 0, z: 0),
                "inputGVector": CIVector(x: 0, y: 1.0, z: 0),
                "inputBVector": CIVector(x: 0, y: 0, z: 1.0),
                "inputBiasVector": CIVector(x: 0.06, y: 0.06, z: 0.06),
            ])
        }

        guard let cgOut = context.createCGImage(output, from: output.extent) else {
            throw ImageFilterError.renderFailed
        }
        return UIImage(cgImage: cgOut, scale: image.scale, orientation: image.imageOrientation)
    }
}

enum ImageFilterError: Error {
    case invalidInput
    case renderFailed
}
