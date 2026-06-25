import Foundation
import CoreLocation

struct FuzzyLocation: Codable, Hashable {
    let label: String
    let lat: Double
    let lon: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
}
