import SwiftUI
import SwiftData
import CoreLocation

@MainActor
@Observable
final class RecordViewModel {
    var originalImages: [UIImage] = []
    var selectedFilter: ImageFilter = .original
    var title: String = ""
    var text: String = ""
    var selectedMood: MoodTag?
    var fuzzyLocation: FuzzyLocation?
    var isPublic = true
    var showsLocation = false
    var canPublish: Bool { !originalImages.isEmpty }
    var isSaving = false
    var errorMessage: String?

    let locationManager = LocationManager()

    func prepareLocationForSharing() async {
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
        guard !originalImages.isEmpty else {
            errorMessage = NSLocalizedString("record.error.no_image", value: "请先选一张照片", comment: "")
            return false
        }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if isPublic && showsLocation && fuzzyLocation == nil {
            await prepareLocationForSharing()
        } else if fuzzyLocation == nil {
            await refreshFuzzyLocation()
        }
        guard let fuzzyLocation else {
            errorMessage = NSLocalizedString("record.error.no_location", value: "无法获取位置", comment: "")
            return false
        }

        isSaving = true
        defer { isSaving = false }

        do {
            var fullDataList: [Data] = []
            var thumbDataList: [Data] = []

            for image in originalImages.prefix(12) {
                let resized = try ImageStorage.resize(image: image, maxLongEdge: 2400)
                let filtered = try ImageFilterEngine.apply(filter: selectedFilter, to: resized)
                fullDataList.append(try ImageStorage.encodeJPEG(filtered, quality: 0.82))
                thumbDataList.append(try ImageStorage.makeThumbnail(filtered, longEdge: 400, quality: 0.7))
            }

            guard let fullData = fullDataList.first, let thumbData = thumbDataList.first else {
                errorMessage = NSLocalizedString("record.error.no_image", value: "请先选一张照片", comment: "")
                return false
            }

            let post = Post(
                taskRef: task.id,
                imageData: fullData,
                thumbnailData: thumbData,
                imageDataList: fullDataList,
                thumbnailDataList: thumbDataList,
                title: title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : title,
                text: trimmed,
                moodTag: selectedMood,
                filterName: selectedFilter.rawValue,
                fuzzyLabel: fuzzyLocation.label,
                fuzzyLat: fuzzyLocation.lat,
                fuzzyLon: fuzzyLocation.lon,
                isPublic: isPublic,
                showsLocation: isPublic && showsLocation,
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
