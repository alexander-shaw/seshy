//
//  ColorContrastHelper.swift
//  EventsApp
//
//  Created by Шоу on 11/27/25.
//

import SwiftUI

enum ColorContrastHelper {
    /// Converts a hex string into normalized RGB tuple.
    private static func rgb(from hex: String) -> (Double, Double, Double)? {
        var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if cleaned.hasPrefix("#") {
            cleaned.removeFirst()
        }
        guard cleaned.count == 6, let value = UInt32(cleaned, radix: 16) else { return nil }
        let r = Double((value & 0xFF0000) >> 16) / 255.0
        let g = Double((value & 0x00FF00) >> 8) / 255.0
        let b = Double(value & 0x0000FF) / 255.0
        return (r, g, b)
    }
    
    private static func luminance(for rgb: (Double, Double, Double)) -> Double {
        func adjust(_ component: Double) -> Double {
            return component <= 0.03928 ? component / 12.92 : pow((component + 0.055) / 1.055, 2.4)
        }
        let r = adjust(rgb.0)
        let g = adjust(rgb.1)
        let b = adjust(rgb.2)
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }
    
    /// Calculates WCAG contrast ratio between two hex colors.
    static func contrastRatio(between hexA: String, and hexB: String) -> Double? {
        guard let rgbA = rgb(from: hexA), let rgbB = rgb(from: hexB) else { return nil }
        let lumA = luminance(for: rgbA) + 0.05
        let lumB = luminance(for: rgbB) + 0.05
        return lumA > lumB ? lumA / lumB : lumB / lumA
    }
    
    /// Checks if a color has sufficient contrast against a dark-mode background.
    static func isValidForDarkMode(hex: String, minimumRatio: Double = 3.0, backgroundHex: String = "#121212") -> Bool {
        guard let ratio = contrastRatio(between: hex, and: backgroundHex) else { return false }
        return ratio >= minimumRatio
    }
}


















