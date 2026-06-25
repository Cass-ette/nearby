import Testing
import Foundation
import CoreLocation
@testable import 附近

struct LocationFuzzerTests {
    @Test func roundsToThousandthsGrid() {
        let coord = CLLocationCoordinate2D(latitude: 31.226123, longitude: 121.426789)
        let fuzzy = LocationFuzzer.fuzzify(coord, label: "测试")
        #expect(fuzzy.lat == 31.226)
        #expect(fuzzy.lon == 121.427)
    }

    @Test func nearbyCoordsRoundToWithinOneThousandth() {
        let a = CLLocationCoordinate2D(latitude: 31.226499, longitude: 121.426500)
        let b = CLLocationCoordinate2D(latitude: 31.226001, longitude: 121.426999)
        let fa = LocationFuzzer.fuzzify(a, label: "")
        let fb = LocationFuzzer.fuzzify(b, label: "")
        #expect(abs(fa.lat - fb.lat) <= 0.001)
        #expect(abs(fa.lon - fb.lon) <= 0.001)
    }

    @Test func negativeCoordinatesHandled() {
        let coord = CLLocationCoordinate2D(latitude: -23.550567, longitude: -46.633308)
        let fuzzy = LocationFuzzer.fuzzify(coord, label: "São Paulo")
        #expect(fuzzy.lat <= 0)
        #expect(fuzzy.lon <= 0)
    }
}
