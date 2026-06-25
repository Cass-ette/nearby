import Foundation

struct Neighborhood: Codable, Identifiable {
    let id: String
    let nameZh: String
    let nameEn: String
    let districtZh: String
    let districtEn: String
    let centerLat: Double
    let centerLon: Double
    let radius: Double
}

struct NeighborhoodFile: Codable {
    let city: String
    let neighborhoods: [Neighborhood]
}

enum NeighborhoodTable {
    static func load() async throws -> [Neighborhood] {
        guard let url = Bundle.main.url(forResource: "neighborhoods", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            throw NeighborhoodTableError.fileNotFound
        }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        guard let file = try? decoder.decode(NeighborhoodFile.self, from: data) else {
            throw NeighborhoodTableError.fileNotFound
        }
        return file.neighborhoods
    }
}

extension [Neighborhood] {
    func resolve(lat: Double, lon: Double) -> Neighborhood? {
        var best: (Neighborhood, Double)?
        for n in self {
            let dLat = lat - n.centerLat
            let dLon = lon - n.centerLon
            let dist = (dLat * dLat + dLon * dLon).squareRoot()
            if dist <= n.radius {
                if best == nil || dist < best!.1 {
                    best = (n, dist)
                }
            }
        }
        return best?.0
    }
}

enum NeighborhoodTableError: Error {
    case fileNotFound
}
