import SwiftUI

extension Color {
    // Neutral tiers
    static let appSurface = Color(light: Color(hex: "#F5F4EF"), dark: Color(hex: "#1C1B18"))
    static let appSurfaceElevated = Color(light: Color(hex: "#ECEAE1"), dark: Color(hex: "#2A2721"))
    static let appSurfaceOverlay = Color(light: Color(hex: "#FFFFFF"), dark: Color(hex: "#38332A"))

    static let appInk = Color(light: Color(hex: "#1C1B16"), dark: Color(hex: "#F2EFE6"))
    static let appMuted = Color(light: Color(hex: "#8D8975"), dark: Color(hex: "#A7A18E"))
    static let appBorder = Color(light: Color(hex: "#DFDCCF"), dark: Color(hex: "#3B3730"))

    // Brand
    static let appPrimary = Color(light: Color(hex: "#4B5723"), dark: Color(hex: "#8FA352"))
    static let appPrimaryDark = Color(light: Color(hex: "#3A4319"), dark: Color(hex: "#6B7A3B"))
    static let appHighlight = Color(light: Color(hex: "#C1512F"), dark: Color(hex: "#E38356"))
    static let appDanger = Color(light: Color(hex: "#B23B3B"), dark: Color(hex: "#E0605E"))

    // Vaccine shortcut card (not a loggable record type)
    static let appVaccine = Color(light: Color(hex: "#2E7D6B"), dark: Color(hex: "#6FBFA8"))
    static let appVaccineBg = Color(light: Color(hex: "#DCEEE8"), dark: Color(hex: "#1B2A26"))
}
