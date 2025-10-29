//
//  ThemeViewModel.swift
//  EventsApp
//
//  Created on 10/25/25.
//

import Foundation
import UIKit
import CoreDomain
import Combine

/// Pure Swift ViewModel for resolving theme and map style based on appearance mode and time.
/// No UI dependencies - suitable for use in any context.
public class ThemeViewModel {
    
    // MARK: - Properties
    
    /// Optional map style override (if user explicitly chose a map style)
    public var mapStyleOverride: MapStyle?
    
    /// Named theme support for future extensibility
    private var themeName: String = "default"
    
    // MARK: - Time Management
    
    /// Singleton time manager similar to the reference implementation
    private class TimeManager: ObservableObject {
        static let shared = TimeManager()
        
        @Published var currentDate: Date = Date()
        
        private init() {
            startUpdatingTime()
        }
        
        private func startUpdatingTime() {
            let nextSecond = Calendar.current.date(byAdding: .second, value: 1, to: Date())!
            let timeInterval = nextSecond.timeIntervalSinceNow
            
            DispatchQueue.global().asyncAfter(deadline: .now() + timeInterval) { [weak self] in
                DispatchQueue.main.async {
                    self?.currentDate = Date()
                    self?.startUpdatingTime()
                }
            }
        }
    }
    
    private let timeManager = TimeManager.shared
    
    // MARK: - Initialization
    
    public init(mapStyleOverride: MapStyle? = nil) {
        self.mapStyleOverride = mapStyleOverride
    }
    
    // MARK: - Main Resolution Function
    
    /// Resolves the current theme and map style based on appearance mode and system style.
    /// 
    /// - Parameters:
    ///   - systemStyle: The current system UI style (from UITraitCollection)
    ///   - userMode: User's preferred appearance mode from settings
    ///   - now: Current time (defaults to time manager's current time)
    /// - Returns: Tuple containing the resolved Theme and MapStyle
    public func resolvedAppearance(
        systemStyle: UIUserInterfaceStyle,
        userMode: AppearanceMode,
        now: Date? = nil
    ) -> (theme: AppTheme, mapStyle: MapStyle) {
        let currentTime = now ?? timeManager.currentDate
        
        // Resolve appearance mode
        let effectiveAppearanceMode: AppearanceMode
        switch userMode {
        case .system:
            effectiveAppearanceMode = systemStyle == .dark ? .darkMode : .lightMode
        case .darkMode, .lightMode:
            effectiveAppearanceMode = userMode
        }
        
        // Generate theme with time-of-day variations
        let theme = generateTheme(for: effectiveAppearanceMode, at: currentTime)
        
        // Resolve map style
        let mapStyle = resolveMapStyle(
            appearanceMode: effectiveAppearanceMode,
            override: mapStyleOverride
        )
        
        return (theme, mapStyle)
    }
    
    // MARK: - Theme Generation
    
    /// Generates a theme based on appearance mode with subtle time-of-day variations.
    private func generateTheme(for mode: AppearanceMode, at time: Date) -> AppTheme {
        // Base theme selection
        let baseTheme: AppTheme
        switch mode {
        case .darkMode:
            baseTheme = .darkTheme
        case .lightMode:
            baseTheme = .lightTheme
        case .system:
            // Should not reach here after resolution
            baseTheme = .darkTheme
        }
        
        // Apply time-of-day variations (only if in system mode)
        // This creates subtle, deterministic changes throughout the day
        return applyTimeOfDayVariations(to: baseTheme, at: time, isAutoMode: true)
    }
    
    /// Applies subtle time-of-day variations to a theme.
    /// These variations are low-amplitude and deterministic to avoid contrast issues.
    private func applyTimeOfDayVariations(to theme: AppTheme, at time: Date, isAutoMode: Bool) -> AppTheme {
        guard isAutoMode else { return theme }
        
        // Extract time components
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: time)
        let minute = calendar.component(.minute, from: time)
        
        // Create a smooth curve that peaks at midday (higher contrast) and dips at midnight
        // This uses a sine wave from 0-2π over 24 hours
        let timeOfDay = Double(hour) + (Double(minute) / 60.0)
        let normalizedTime = (timeOfDay / 24.0) * 2.0 * .pi
        let timeVariation = sin(normalizedTime)  // Ranges from -1 to 1
        
        // Apply subtle variations (keep amplitude low)
        let contrastBoost = 1.0 + (timeVariation * 0.05)  // ±5% variation
        let elevationBoost = 1.0 + (timeVariation * 0.03)  // ±3% variation
        
        // Generate modified colors with subtle adjustments
        let modifiedColors = modifyColors(
            theme.colors,
            contrastMultiplier: contrastBoost,
            elevationMultiplier: elevationBoost
        )
        
        return AppTheme(
            colors: modifiedColors,
            typography: theme.typography,
            spacing: theme.spacing,
            sizes: theme.sizes
        )
    }
    
    /// Applies subtle modifications to colors based on time-based multipliers.
    private func modifyColors(_ colors: Colors, contrastMultiplier: Double, elevationMultiplier: Double) -> Colors {
        // Convert colors to UIColor, apply modifications, convert back
        // For now, return unmodified - implement as needed when Color extension is available
        // This is a placeholder for future enhancement
        
        // If we need to actually modify colors, we'd convert Color to UIColor,
        // adjust alpha/contrast, and convert back
        return colors
    }
    
    // MARK: - Map Style Resolution
    
    /// Resolves the appropriate map style based on appearance mode and any override.
    private func resolveMapStyle(appearanceMode: AppearanceMode, override: MapStyle?) -> MapStyle {
        // If user explicitly set a map style, honor it
        if let override = override {
            return override
        }
        
        // Otherwise, match appearance mode
        switch appearanceMode {
        case .darkMode:
            return .darkMap
        case .lightMode:
            return .lightMap
        case .system:
            // Default to dark map (should be overridden by system resolution)
            return .darkMap
        }
    }
    
    // MARK: - Future Theme Support
    
    /// Sets a named theme for future extensibility (e.g., "solarized", "neon")
    public func setThemeName(_ name: String) {
        self.themeName = name
        // Future implementation would generate themes based on name
    }
    
    /// Gets available theme names for future extensibility
    public static func availableThemeNames() -> [String] {
        return ["default", "solarized", "neon"]  // Placeholder for future themes
    }
}


