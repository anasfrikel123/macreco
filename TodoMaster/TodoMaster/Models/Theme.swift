import SwiftUI
#if os(iOS)
import UIKit
#endif

public enum Theme: String, CaseIterable, Codable {
    case light = "Light"
    case dark = "Dark"
    case system = "System"
    
    public var name: String {
        return self.rawValue
    }
    
    public var isDarkMode: Bool {
        switch self {
        case .light:
            return false
        case .dark:
            return true
        case .system:
            #if os(iOS)
            return UITraitCollection.current.userInterfaceStyle == .dark
            #else
            return false
            #endif
        }
    }
    
    public var accentColor: Color {
        switch self {
        case .light, .system:
            return .blue
        case .dark:
            return .blue.opacity(0.9)
        }
    }
    
    public var colorScheme: ColorScheme? {
        switch self {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return nil
        }
    }
}

// MARK: - Color Extensions
extension Color: Codable {
    private enum CodingKeys: String, CodingKey {
        case red, green, blue, opacity
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let red = try container.decode(Double.self, forKey: .red)
        let green = try container.decode(Double.self, forKey: .green)
        let blue = try container.decode(Double.self, forKey: .blue)
        let opacity = try container.decode(Double.self, forKey: .opacity)
        
        self.init(red: red, green: green, blue: blue, opacity: opacity)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        #if os(iOS)
        let cgColor = UIColor(self).cgColor
        let components = cgColor.components ?? [0, 0, 0, 1]
        #else
        let components = [0.0, 0.0, 0.0, 1.0] // Default to black for non-iOS platforms
        #endif
        
        try container.encode(Double(components[0]), forKey: .red)
        try container.encode(Double(components[1]), forKey: .green)
        try container.encode(Double(components[2]), forKey: .blue)
        try container.encode(Double(components[3]), forKey: .opacity)
    }
    
    public init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }
        
        let red = Double((rgb & 0xFF0000) >> 16) / 255.0
        let green = Double((rgb & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgb & 0x0000FF) / 255.0
        
        self.init(red: red, green: green, blue: blue)
    }
    
    public var hex: String {
        #if os(iOS)
        let components = UIColor(self).cgColor.components
        let r = components?[0] ?? 0
        let g = components?[1] ?? 0
        let b = components?[2] ?? 0
        
        return String(format: "#%02X%02X%02X",
                     Int(r * 255),
                     Int(g * 255),
                     Int(b * 255))
        #else
        return "#000000"
        #endif
    }
} 
