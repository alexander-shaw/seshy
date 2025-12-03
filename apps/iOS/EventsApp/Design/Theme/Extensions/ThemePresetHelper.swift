//
//  ThemePresetHelper.swift
//  EventsApp
//
//  Created by Auto on 1/25/25.
//

import UIKit
import SwiftUI

/// Helper for generating theme preset variants (Bold, Muted, Dark) from a base color
public enum ThemePresetHelper {
    
    /// Theme mode options
    public enum ThemeMode: String, CaseIterable {
        case auto = "auto"
        case bold = "bold"
        case muted = "muted"
        case dark = "dark"
        case custom = "custom"
        
        public var displayName: String {
            switch self {
            case .auto: return "Auto"
            case .bold: return "Bold"
            case .muted: return "Muted"
            case .dark: return "Dark"
            case .custom: return "Custom"
            }
        }
    }
    
    /// Result containing primary and secondary colors for a theme
    public struct ThemeColors {
        public let primaryHex: String
        public let secondaryHex: String
        
        public init(primaryHex: String, secondaryHex: String) {
            self.primaryHex = primaryHex
            self.secondaryHex = secondaryHex
        }
    }
    
    /// Generates theme colors based on a base color and mode
    /// - Parameters:
    ///   - basePrimaryHex: The base primary color hex (e.g., "#FF5733")
    ///   - baseSecondaryHex: Optional base secondary color hex. If nil, uses a derived secondary.
    ///   - mode: The theme mode to apply
    /// - Returns: ThemeColors with adjusted primary and secondary colors
    public static func generateThemeColors(
        basePrimaryHex: String,
        baseSecondaryHex: String? = nil,
        mode: ThemeMode
    ) -> ThemeColors {
        guard let baseColor = Color(hex: basePrimaryHex) else {
            // Fallback to original if parsing fails
            return ThemeColors(
                primaryHex: basePrimaryHex,
                secondaryHex: baseSecondaryHex ?? basePrimaryHex
            )
        }
        
        let uiColor = UIColor(baseColor)
        var (h, s, b, a): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 1)
        uiColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        
        let adjustedPrimary: UIColor
        let adjustedSecondary: UIColor
        
        switch mode {
        case .auto:
            // Use original colors
            adjustedPrimary = uiColor
            adjustedSecondary = baseSecondaryHex.flatMap { Color(hex: $0) }.map { UIColor($0) } ?? uiColor
            
        case .bold:
            // Increase saturation and brightness for bold look
            adjustedPrimary = UIColor(
                hue: h,
                saturation: min(1.0, s * 1.3),
                brightness: min(1.0, b * 1.1),
                alpha: a
            )
            // Secondary: slightly less saturated
            adjustedSecondary = UIColor(
                hue: h,
                saturation: min(1.0, s * 1.1),
                brightness: min(1.0, b * 0.95),
                alpha: a
            )
            
        case .muted:
            // Decrease saturation for muted look
            adjustedPrimary = UIColor(
                hue: h,
                saturation: max(0.0, s * 0.6),
                brightness: min(1.0, b * 0.9),
                alpha: a
            )
            // Secondary: even more muted
            adjustedSecondary = UIColor(
                hue: h,
                saturation: max(0.0, s * 0.4),
                brightness: min(1.0, b * 0.85),
                alpha: a
            )
            
        case .dark:
            // Decrease brightness for dark look
            adjustedPrimary = UIColor(
                hue: h,
                saturation: min(1.0, s * 1.1),
                brightness: max(0.0, b * 0.5),
                alpha: a
            )
            // Secondary: even darker
            adjustedSecondary = UIColor(
                hue: h,
                saturation: min(1.0, s * 0.9),
                brightness: max(0.0, b * 0.4),
                alpha: a
            )
            
        case .custom:
            // Use original colors (custom means user-defined)
            adjustedPrimary = uiColor
            adjustedSecondary = baseSecondaryHex.flatMap { Color(hex: $0) }.map { UIColor($0) } ?? uiColor
        }
        
        return ThemeColors(
            primaryHex: hexString(from: adjustedPrimary),
            secondaryHex: hexString(from: adjustedSecondary)
        )
    }
    
    /// Gets the current theme colors for an event, applying the theme mode if needed
    /// - Parameters:
    ///   - themePrimaryHex: The event's theme primary hex (may be nil)
    ///   - themeSecondaryHex: The event's theme secondary hex (may be nil)
    ///   - themeMode: The event's theme mode (defaults to "auto")
    ///   - fallbackPrimaryHex: Fallback color if themePrimaryHex is nil
    ///   - fallbackSecondaryHex: Fallback color if themeSecondaryHex is nil
    /// - Returns: ThemeColors with the computed colors
    public static func currentThemeColors(
        themePrimaryHex: String?,
        themeSecondaryHex: String?,
        themeMode: String?,
        fallbackPrimaryHex: String? = nil,
        fallbackSecondaryHex: String? = nil
    ) -> ThemeColors {
        let mode = ThemeMode(rawValue: themeMode ?? "auto") ?? .auto
        
        // Use theme colors if available, otherwise fallback
        let basePrimary = themePrimaryHex ?? fallbackPrimaryHex ?? "#808080"
        let baseSecondary = themeSecondaryHex ?? fallbackSecondaryHex ?? basePrimary
        
        // If mode is auto, return as-is. Otherwise apply preset transformation
        if mode == .auto {
            return ThemeColors(primaryHex: basePrimary, secondaryHex: baseSecondary)
        } else {
            return generateThemeColors(basePrimaryHex: basePrimary, baseSecondaryHex: baseSecondary, mode: mode)
        }
    }
    
    // MARK: - Private Helpers
    
    private static func hexString(from color: UIColor) -> String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let rInt = Int(r * 255)
        let gInt = Int(g * 255)
        let bInt = Int(b * 255)
        
        return String(format: "#%02X%02X%02X", rInt, gInt, bInt)
    }
}

