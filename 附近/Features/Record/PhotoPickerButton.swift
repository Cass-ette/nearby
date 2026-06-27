import SwiftUI
import PhotosUI

struct PhotoPickerButton: View {
    @Binding var images: [UIImage]
    var onPick: () -> Void = {}

    @State private var pickerItems: [PhotosPickerItem] = []

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Rectangle()
                .fill(Color.paper100)
                .frame(maxWidth: .infinity)
                .frame(height: 320)
                .overlay {
                    if let image = images.first {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    } else {
                        VStack(spacing: Spacing.s) {
                            Image(systemName: "camera")
                                .font(.system(size: 28))
                                .foregroundStyle(Color.ink500)
                            Text(NSLocalizedString("record.photo.placeholder", value: "点击选择照片", comment: ""))
                                .font(.caption)
                                .foregroundStyle(Color.ink500)
                            Text(NSLocalizedString("record.photo.limit", value: "最多 12 张", comment: ""))
                                .font(.caption2)
                                .foregroundStyle(Color.ink300)
                        }
                    }
                }
                .clipped()
                .cornerRadius(Radius.image)
                .overlay(alignment: .topTrailing) {
                    if !images.isEmpty {
                        Text("\(images.count)/12")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.paper50)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.ink900.opacity(0.55))
                            .clipShape(Capsule())
                            .padding(Spacing.s)
                    }
                }
                .overlay {
                    PhotosPicker(selection: $pickerItems, maxSelectionCount: 12, matching: .images) {
                        Color.clear.contentShape(Rectangle())
                    }
                }

            if !images.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.s) {
                        ForEach(Array(images.enumerated()), id: \.offset) { index, image in
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 56, height: 56)
                                .clipShape(RoundedRectangle(cornerRadius: Radius.image, style: .continuous))
                                .overlay(alignment: .topTrailing) {
                                    Text("\(index + 1)")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundStyle(Color.paper50)
                                        .frame(width: 16, height: 16)
                                        .background(Color.ink900.opacity(0.55))
                                        .clipShape(Circle())
                                        .padding(3)
                                }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .onChange(of: pickerItems) { _, newItems in
            Task {
                var pickedImages: [UIImage] = []
                for item in newItems.prefix(12) {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        pickedImages.append(uiImage)
                    }
                }

                await MainActor.run {
                    images = pickedImages
                    onPick()
                }
            }
        }
    }
}
