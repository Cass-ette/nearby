import SwiftUI

struct MineView: View {
    var body: some View {
        NavigationStack {
            Text("我的")
                .font(.titleDisplay)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .paperBackground()
    }
}
