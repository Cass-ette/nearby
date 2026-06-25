import Foundation
import CoreLocation

enum LocationFuzzer {
    static func fuzzify(_ coord: CLLocationCoordinate2D, label: String) -> FuzzyLocation {
        let lat = (coord.latitude * 1000).rounded() / 1000
        let lon = (coord.longitude * 1000).rounded() / 1000
        return FuzzyLocation(label: label, lat: lat, lon: lon)
    }
}
