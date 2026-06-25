import SwiftUI
import SwiftData
import CoreLocation

@MainActor
@Observable
final class RecordViewModel {
    var originalImage: UIImage?
    var selectedFilter: ImageFilter = .original
    var title: String = ""
    var text: String = ""
    var selectedMood: MoodTag?
    var fuzzyLocation: FuzzyLocation?
    var canPublish: Bool { text.trimmingCharacters(in: .whitespacesAndNewlines).count >= 6 && originalImage != nil }
    var isSaving = false
    var errorMessage: String?

    let locationManager = LocationManager()

    func setupLocation() async {
        if locationManager.currentCoord == nil {
            locationManager.requestPermission()
            locationManager.requestLocation()
            try? await Task.sleep(for: .seconds(2))
        }
        await refreshFuzzyLocation()
    }

    func refreshFuzzyLocation() async {
        let coord = locationManager.currentCoord ?? LocationManager.fallbackCoord
        let label = await GeoLabelResolver.resolve(lat: coord.latitude, lon: coord.longitude)
        fuzzyLocation = LocationFuzzer.fuzzify(coord, label: label)
    }

    func save(modelContext: ModelContext, task: DailyTask) async -> Bool {
        guard let originalImage else {
            errorMessage = NSLocalizedString("record.error.no_image", value: "请先选一张照片", comment: "")
            return false
        }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 6 else {
            errorMessage = NSLocalizedString("record.error.short_text", value: "再多写一句吧", comment: "")
            return false
        }
        guard let fuzzyLocation else {
            errorMessage = NSLocalizedString("record.error.no_location", value: "无法获取位置", comment: "")
            return false
        }

        isSaving = true
        defer { isSaving = false }

        do {
            let resized = try ImageStorage.resize(image: originalImage, maxLongEdge: 2400)
            let filtered = try ImageFilterEngine.apply(filter: selectedFilter, to: resized)
            let fullData = try ImageStorage.encodeJPEG(filtered, quality: 0.82)
            let thumbData = try ImageStorage.makeThumbnail(filtered, longEdge: 400, quality: 0.7)

            let post = Post(
                taskRef: task.id,
                imageData: fullData,
                thumbnailData: thumbData,
                title: title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : title,
                text: trimmed,
                moodTag: selectedMood,
                filterName: selectedFilter.rawValue,
                fuzzyLabel: fuzzyLocation.label,
                fuzzyLat: fuzzyLocation.lat,
                fuzzyLon: fuzzyLocation.lon,
                isOwn: true,
                authorId: CurrentUser.id,
                authorName: CurrentUser.displayName
            )
            modelContext.insert(post)
            try modelContext.save()
            return true
        } catch {
            errorMessage = NSLocalizedString("record.error.save_failed", value: "保存失败，请重试", comment: "")
            return false
        }
    }
}
