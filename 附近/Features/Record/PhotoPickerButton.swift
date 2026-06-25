import SwiftUI
import PhotosUI

struct PhotoPickerButton: View {
    @Binding var image: UIImage?
    var onPick: () -> Void = {}

    @State private var pickerItem: PhotosPickerItem?

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 360)
                    .clipped()
                    .cornerRadius(Radius.image)
            } else {
                ZStack {
                    Color.paper100
                    VStack(spacing: Spacing.s) {
                        Image(systemName: "camera")
                            .font(.system(size: 28))
                            .foregroundStyle(Color.ink500)
                        Text(NSLocalizedString("record.photo.placeholder", value: "点击选择照片", comment: ""))
                            .font(.caption)
                            .foregroundStyle(Color.ink500)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 360)
                .cornerRadius(Radius.image)
            }
        }
        .overlay {
            PhotosPicker(selection: $pickerItem, matching: .images) {
                Color.clear.contentShape(Rectangle())
            }
        }
        .onChange(of: pickerItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    await MainActor.run {
                        image = uiImage
                        onPick()
                    }
                }
            }
        }
    }
}
