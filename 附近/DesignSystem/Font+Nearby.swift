import SwiftUI

extension Font {
    // 中文标题：宋体；英文标题：New York
    static let titleDisplay = Font.custom("SongtiSC-Black", size: 30, relativeTo: .largeTitle)
    static let taskTitle = Font.custom("SongtiSC-Bold", size: 23, relativeTo: .title2)
    static let sectionTitle = Font.custom("SongtiSC-Bold", size: 18, relativeTo: .headline)
    static let bodySerif = Font.custom("SongtiSC-Regular", size: 17, relativeTo: .body)
    static let caption = Font.system(size: 13, weight: .light)
}

// Helper to render Songti for Chinese, system serif for English (font fallback handled by iOS)
extension View {
    func serifTitle() -> some View {
        self.font(.taskTitle)
    }
}
