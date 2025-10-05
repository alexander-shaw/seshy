//
//  ColorPalette.swift
//  EventsApp
//
//  Created by Шоу on 10/1/25.
//

import SwiftUI
import UIKit

extension Theme {
    struct ColorPalette {
        static let accent: Color = Color.blue
        static let background: Color = Color(hex: "#121212")
        static let surface: Color = Color(hex: "#292929")
        static let mainText: Color = Color(hex: "#FFFFFF")
        static let offText: Color = Color(hex: "#B3B3B3")
        static let error: Color = Color.red
    }
}

// MARK: - TO USE HEX CODES:
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt64()
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        (r, g, b) = (int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        self.init(red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255)
    }

    func toHexString(includeAlpha: Bool = false) -> String {
        let uiColor = UIColor(self)

        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 1

        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        if includeAlpha {
            return String(format: "#%02X%02X%02X%02X", lroundf(Float(red * 255)), lroundf(Float(green * 255)), lroundf(Float(blue * 255)), lroundf(Float(alpha * 255)))
        } else {
            return String(format: "#%02X%02X%02X", lroundf(Float(red * 255)), lroundf(Float(green * 255)), lroundf(Float(blue * 255)))
        }
    }
}
