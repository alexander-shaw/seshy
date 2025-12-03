//
//  MediaColorHelper.swift
//  EventsApp
//
//  Created by Auto on 1/25/25.
//

import SwiftUI
import CoreData

/// Helper for getting colors from Media entities with fallback support for legacy media
public enum MediaColorHelper {
    
    /// Gets gradient colors for a media item, computing colors if missing
    /// - Parameters:
    ///   - media: The Media entity
    ///   - fallbackColor: Optional fallback color if media has no colors
    /// - Returns: Array of Colors for gradient (primary, secondary)
    public static func gradientColors(
        for media: Media,
        fallbackColor: Color? = nil
    ) -> [Color] {
        // Try to get primary and secondary colors
        let primaryHex = media.primaryColorHex ?? media.averageColorHex
        let secondaryHex = media.secondaryColorHex ?? media.averageColorHex ?? primaryHex
        
        if let primaryHex = primaryHex, let primaryColor = Color(hex: primaryHex) {
            if let secondaryHex = secondaryHex, let secondaryColor = Color(hex: secondaryHex), secondaryHex != primaryHex {
                return [primaryColor, secondaryColor]
            } else {
                // Single color - create a subtle gradient
                return [primaryColor, primaryColor.opacity(0.8)]
            }
        }
        
        // Fallback
        if let fallback = fallbackColor {
            return [fallback, fallback.opacity(0.8)]
        }
        
        // Default neutral gradient
        return [
            Color(red: 0.2, green: 0.2, blue: 0.25),
            Color(red: 0.15, green: 0.15, blue: 0.2)
        ]
    }
    
    /// Computes and stores colors for legacy media that doesn't have them
    /// This should be called asynchronously when media is loaded
    /// - Parameters:
    ///   - media: The Media entity (must be in a valid context)
    ///   - imageData: The image data to extract colors from
    /// - Returns: True if colors were computed and stored, false otherwise
    @MainActor
    public static func computeAndStoreColors(for media: Media, imageData: Data) -> Bool {
        guard let colorResult = DominantColorExtractor.extractColors(from: imageData) else {
            return false
        }
        
        // Update media in its context
        media.primaryColorHex = colorResult.primaryColorHex
        media.secondaryColorHex = colorResult.secondaryColorHex
        
        // Also update averageColorHex for backward compatibility
        if media.averageColorHex == nil {
            media.averageColorHex = colorResult.primaryColorHex
        }
        
        return true
    }
}





