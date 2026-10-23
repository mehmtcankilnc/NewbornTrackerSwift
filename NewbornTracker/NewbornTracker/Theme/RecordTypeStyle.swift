import SwiftUI

extension RecordType {
    /// Foreground color for icons and labels of this record type.
    var accent: Color {
        switch self {
        case .poop: Color(light: Color(hex: "#A9744F"), dark: Color(hex: "#C99872"))
        case .piss: Color(light: Color(hex: "#B08A1E"), dark: Color(hex: "#D4B354"))
        case .feed: Color(light: Color(hex: "#5C6B2E"), dark: Color(hex: "#8FA352"))
        case .sleep: Color(light: Color(hex: "#6E6B8F"), dark: Color(hex: "#9C99C2"))
        case .fever: Color(light: Color(hex: "#B23B3B"), dark: Color(hex: "#E0605E"))
        case .medicine: Color(light: Color(hex: "#4A6FA5"), dark: Color(hex: "#8FADD6"))
        case .vitamin: Color(light: Color(hex: "#C7891E"), dark: Color(hex: "#E0B054"))
        }
    }

    /// Soft tinted background behind this record type's icon.
    var accentBackground: Color {
        switch self {
        case .poop: Color(light: Color(hex: "#EFE6DB"), dark: Color(hex: "#2B2119"))
        case .piss: Color(light: Color(hex: "#F3EDD8"), dark: Color(hex: "#2C2717"))
        case .feed: Color(light: Color(hex: "#E6E9D8"), dark: Color(hex: "#232819"))
        case .sleep: Color(light: Color(hex: "#E6E5EE"), dark: Color(hex: "#211F2B"))
        case .fever: Color(light: Color(hex: "#F3DCDA"), dark: Color(hex: "#2E1E1D"))
        case .medicine: Color(light: Color(hex: "#DCE6F3"), dark: Color(hex: "#1D2530"))
        case .vitamin: Color(light: Color(hex: "#F5E6C8"), dark: Color(hex: "#2C2417"))
        }
    }
}
