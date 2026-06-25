import SwiftUI

struct MapView: View {
    var body: some View {
        NavigationStack {
            Text("地图")
                .font(.titleDisplay)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .paperBackground()
    }
}
