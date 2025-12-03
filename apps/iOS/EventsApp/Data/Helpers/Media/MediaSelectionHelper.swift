//
//  MediaSelectionHelper.swift
//  EventsApp
//
//  Created by Шоу on 10/29/25.
//

import Foundation
import SwiftUI
import PhotosUI
import UIKit
import UniformTypeIdentifiers

public enum MediaSelectionHelper {
    
    // Converts PhotosPickerItem array to MediaItem array.
    // Processes items sequentially to avoid overwhelming the system.
    // Color extraction is skipped during selection - it will happen during upload.
    public static func processPickerItems(_ items: [PhotosPickerItem], maxItems: Int = 4) async -> [MediaItem] {
        var mediaItems: [MediaItem] = []
        
        // Process items sequentially to avoid system overload
        // Color extraction is deferred to upload time for better performance
        for (index, item) in items.prefix(maxItems).enumerated() {
            if let mediaItem = await processPickerItem(item, position: Int16(index)) {
                mediaItems.append(mediaItem)
            }
        }
        
        return mediaItems
    }
    
    // Converts a single PhotosPickerItem to MediaItem.
    // Only loads and compresses images - color extraction is deferred to upload time.
    private static func processPickerItem(_ item: PhotosPickerItem, position: Int16) async -> MediaItem? {
        // Only process images
        guard item.supportedContentTypes.contains(where: { $0.conforms(to: .image) }) else {
            return nil
        }
        
        // Load data - this is async and may be slow
        guard let data = try? await item.loadTransferable(type: Data.self) else {
            return nil
        }
        
        // Move image processing to background thread
        return await Task.detached(priority: .userInitiated) {
            var mimeType: String? = "image/jpeg"
            var imageData: Data? = nil
            
            // Create UIImage and compress - this is CPU intensive but necessary
            guard let image = UIImage(data: data) else {
                return nil
            }
            
            // Compress image off main thread
            if let compressedData = image.jpegData(compressionQuality: 0.8) {
                imageData = compressedData
            } else {
                imageData = data
            }
            
            // Extract colors using fast, simplified algorithm
            // This runs quickly because we downsample to 50x50 and use simple k-means
            let colorResult = DominantColorExtractor.extractColors(from: image)
            
            if let colorResult = colorResult {
                return MediaItem(
                    imageData: imageData,
                    mimeType: mimeType,
                    position: position,
                    averageColorHex: colorResult.primaryColorHex,
                    primaryColorHex: colorResult.primaryColorHex,
                    secondaryColorHex: colorResult.secondaryColorHex
                )
            } else {
                // Fallback: use average color if extraction fails
                let averageColor = ColorAnalysisHelper.averageColorHex(from: image)
                return MediaItem(
                    imageData: imageData,
                    mimeType: mimeType,
                    position: position,
                    averageColorHex: averageColor,
                    primaryColorHex: averageColor,
                    secondaryColorHex: averageColor
                )
            }
        }.value
    }
}
