//
//  Color+Hex.swift
//  EventsApp
//
//  Created by Шоу on 10/14/25.
//

import SwiftUI
import UIKit

public extension Color {
    // Initializes from 6-digit hex, with or without "#".
    init?(hex: String) {
        var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if cleaned.hasPrefix("#") { cleaned.removeFirst() }
        guard cleaned.count == 6, let rgb = UInt32(cleaned, radix: 16) else { return nil }
        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        self = Color(red: r, green: g, blue: b)
    }

    func toHexString(includeAlpha: Bool = false) -> String {
        let uiColor = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 1
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        if includeAlpha {
            return String(format: "#%02X%02X%02X%02X", lroundf(Float(r * 255)), lroundf(Float(g * 255)), lroundf(Float(b * 255)), lroundf(Float(a * 255)))
        } else {
            return String(format: "#%02X%02X%02X", lroundf(Float(r * 255)), lroundf(Float(g * 255)), lroundf(Float(b * 255)))
        }
    }

    // Compare approximate equality in sRGB for selection state.
    func matches(_ other: Color, tolerance: CGFloat = 0.01) -> Bool {
        guard let a = self.uiColor?.srgbComponents, let b = other.uiColor?.srgbComponents else { return false }
        return abs(a.r - b.r) < tolerance && abs(a.g - b.g) < tolerance && abs(a.b - b.b) < tolerance && abs(a.a - b.a) < 0.02
    }

    // 6-digit hex string for this color (sRGB). Returns nil if not convertible.
    var hex6: String? {
        guard let c = uiColor?.srgbComponents else { return nil }
        let r = Int(round(c.r * 255))
        let g = Int(round(c.g * 255))
        let b = Int(round(c.b * 255))
        return String(format: "%02X%02X%02X", r, g, b)
    }

    fileprivate var uiColor: UIColor? {
        UIColor(self)
    }
}
