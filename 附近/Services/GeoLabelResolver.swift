import Foundation
import CoreLocation

enum GeoLabelResolver {
    nonisolated(unsafe) private static var cache: [String: (label: String, expiresAt: Date)] = [:]
    private static let cacheTTL: TimeInterval = 86_400

    static func resolve(lat: Double, lon: Double) async -> String {
        let key = String(format: "%.3f_%.3f", lat, lon)
        if let cached = cache[key], cached.expiresAt > Date() {
            return cached.label
        }

        if let label = await tryReverseGeocode(lat: lat, lon: lon) {
            cache[key] = (label, Date().addingTimeInterval(cacheTTL))
            return label
        }

        if let neighborhoods = try? await NeighborhoodTable.load(),
           let n = neighborhoods.resolve(lat: lat, lon: lon) {
            let locale = Locale.current.language.languageCode?.identifier ?? "zh"
            let label = locale == "en"
                ? "\(n.nameEn) · \(n.districtEn)"
                : "\(n.nameZh) · \(n.districtZh)"
            cache[key] = (label, Date().addingTimeInterval(cacheTTL))
            return label
        }

        return NSLocalizedString("location.unknown", value: "附近 · 此刻", comment: "")
    }

    private static func tryReverseGeocode(lat: Double, lon: Double) async -> String? {
        await withCheckedContinuation { continuation in
            let geocoder = CLGeocoder()
            let location = CLLocation(latitude: lat, longitude: lon)
            geocoder.reverseGeocodeLocation(location) { placemarks, _ in
                guard let p = placemarks?.first else {
                    continuation.resume(returning: nil)
                    return
                }
                let thoroughfare = p.thoroughfare ?? ""
                let subLocality = p.subLocality ?? p.locality ?? ""
                if thoroughfare.isEmpty {
                    continuation.resume(returning: nil)
                    return
                }
                let label = subLocality.isEmpty ? thoroughfare : "\(thoroughfare) · \(subLocality)"
                continuation.resume(returning: label)
            }
        }
    }
}
