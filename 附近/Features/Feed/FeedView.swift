import SwiftUI

struct FeedView: View {
    var body: some View {
        NavigationStack {
            Text("时间流")
                .font(.titleDisplay)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .paperBackground()
    }
}
