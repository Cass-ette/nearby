import SwiftUI

extension Color {
    // Surfaces: warm, Apple-like neutrals
    static let paper50 = Color(red: 0xF8/255, green: 0xF5/255, blue: 0xEE/255)
    static let paper100 = Color(red: 0xFF/255, green: 0xFD/255, blue: 0xF8/255)
    static let paper200 = Color(red: 0xEA/255, green: 0xE2/255, blue: 0xD6/255)
    static let surfaceElevated = Color.white.opacity(0.82)

    // Text: close to iOS label hierarchy
    static let ink900 = Color(red: 0x1D/255, green: 0x1D/255, blue: 0x1F/255)
    static let ink700 = Color(red: 0x3A/255, green: 0x3A/255, blue: 0x3C/255)
    static let ink500 = Color(red: 0x77/255, green: 0x72/255, blue: 0x6A/255)
    static let ink300 = Color(red: 0xC9/255, green: 0xC1/255, blue: 0xB6/255)

    // Accent: gentle location red with soft companions
    static let cinnabar = Color(red: 0xD9/255, green: 0x5A/255, blue: 0x43/255)
    static let cinnabarDeep = Color(red: 0xB9/255, green: 0x3F/255, blue: 0x31/255)
    static let sage = Color(red: 0xA8/255, green: 0xBC/255, blue: 0xAF/255)
    static let sand = Color(red: 0xE6/255, green: 0xD3/255, blue: 0xAD/255)

    // Barely-there glass tints
    static let glassSage = Color(red: 0xE8/255, green: 0xF0/255, blue: 0xEA/255)
    static let glassBlush = Color(red: 0xFA/255, green: 0xEA/255, blue: 0xE6/255)
    static let glassButter = Color(red: 0xFA/255, green: 0xF1/255, blue: 0xD8/255)
    static let glassMist = Color(red: 0xE8/255, green: 0xEE/255, blue: 0xF4/255)

    // Mood colors
    static let moodSerene = Color(red: 0xBD/255, green: 0xCF/255, blue: 0xC5/255)      // 宁静
    static let moodCurious = Color(red: 0xD9/255, green: 0xC9/255, blue: 0x98/255)     // 好奇
    static let moodMelancholy = Color(red: 0xA9/255, green: 0xB7/255, blue: 0xC9/255)  // 惆怅
    static let moodTender = Color(red: 0xF0/255, green: 0xD1/255, blue: 0xCB/255)      // 温柔
    static let moodSurprise = Color(red: 0xF0/255, green: 0xC9/255, blue: 0x8C/255)    // 惊喜
}
