import Testing
import Foundation
@testable import 附近

struct NeighborhoodTableTests {
    @Test func loadsAtLeastTenNeighborhoods() async throws {
        let table = try await NeighborhoodTable.load()
        #expect(table.count >= 10)
    }

    @Test func resolvesClosestNeighborhood() async throws {
        let table = try await NeighborhoodTable.load()
        let resolved = table.resolve(lat: 31.2265, lon: 121.4262)
        #expect(resolved?.nameZh == "愚园路")
    }

    @Test func returnsNilWhenTooFar() async throws {
        let table = try await NeighborhoodTable.load()
        let resolved = table.resolve(lat: 39.904, lon: 116.407)
        #expect(resolved == nil)
    }
}
