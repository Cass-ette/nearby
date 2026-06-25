import SwiftUI

struct TodayView: View {
    var body: some View {
        NavigationStack {
            Text("今日")
                .font(.titleDisplay)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .paperBackground()
    }
}
