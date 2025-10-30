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
import AVFoundation
import UniformTypeIdentifiers

public enum MediaSelectionHelper {
    
    // Converts PhotosPickerItem array to MediaItem array.
    @MainActor
    public static func processPickerItems(_ items: [PhotosPickerItem], maxItems: Int = 4) async -> [MediaItem] {
        var mediaItems: [MediaItem] = []
        
        for (index, item) in items.prefix(maxItems).enumerated() {
            if let mediaItem = await processPickerItem(item, position: Int16(index)) {
                mediaItems.append(mediaItem)
            }
        }
        
        return mediaItems
    }
    
    // Converts a single PhotosPickerItem to MediaItem.
    @MainActor
    private static func processPickerItem(_ item: PhotosPickerItem, position: Int16) async -> MediaItem? {
        // First, try to determine the type from supported content types.
        var isImage = false
        var isVideo = false
        
        // Check if item supports image types.
        if item.supportedContentTypes.contains(where: { $0.conforms(to: .image) }) {
            isImage = true
        }

        // Check if item supports video types.
        else if item.supportedContentTypes.contains(where: { $0.conforms(to: .movie) }) {
            isVideo = true
        }
        
        // Try to get data.
        guard let data = try? await item.loadTransferable(type: Data.self) else {
            return nil
        }
        
        var mimeType: String? = nil
        var imageData: Data? = nil
        var videoData: Data? = nil
        var thumbnailData: Data? = nil
        
        // If determined to be an image from content types or if we can create UIImage from data:
        if isImage || UIImage(data: data) != nil {
            mimeType = "image/jpeg"  // Default, could be more specific.
            imageData = data
            thumbnailData = data  // For images, thumbnail is the same.

            // Try to create UIImage to verify and compress.
            if let image = UIImage(data: data) {
                if let compressedData = image.jpegData(compressionQuality: 0.8) {
                    imageData = compressedData
                    thumbnailData = compressedData
                }
            }
        } else if isVideo {
            mimeType = "video/mp4"  // Default, could be more specific.
            videoData = data
            
            // Generate thumbnail for video.
            if let thumbnail = await generateVideoThumbnail(data: data) {
                thumbnailData = thumbnail
            }
        } else {
            // Fallback: try to infer from data.
            if let image = UIImage(data: data) {
                mimeType = "image/jpeg"
                if let compressedData = image.jpegData(compressionQuality: 0.8) {
                    imageData = compressedData
                    thumbnailData = compressedData
                }
            } else {
                // Assume video or skip; try to generate thumbnail.
                mimeType = "video/mp4"
                videoData = data
                if let thumbnail = await generateVideoThumbnail(data: data) {
                    thumbnailData = thumbnail
                } else {
                    return nil  // Can't process this media type.
                }
            }
        }
        
        guard imageData != nil || videoData != nil else { return nil }
        
        return MediaItem(
            imageData: imageData,
            videoData: videoData,
            thumbnailData: thumbnailData,
            mimeType: mimeType,
            position: position
        )
    }
    
    // Generates a thumbnail from video data.
    @MainActor
    private static func generateVideoThumbnail(data: Data) async -> Data? {
        return await withCheckedContinuation { continuation in
            // Create temporary file for AVAsset.
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mp4")
            
            do {
                try data.write(to: tempURL)
                let asset = AVAsset(url: tempURL)
                let imageGenerator = AVAssetImageGenerator(asset: asset)
                imageGenerator.appliesPreferredTrackTransform = true
                
                let time = CMTime(seconds: 0.0, preferredTimescale: 600)
                let cgImage = try? imageGenerator.copyCGImage(at: time, actualTime: nil)
                
                // Clean up.
                try? FileManager.default.removeItem(at: tempURL)
                
                if let cgImage = cgImage {
                    let uiImage = UIImage(cgImage: cgImage)
                    let thumbnailData = uiImage.jpegData(compressionQuality: 0.7)
                    continuation.resume(returning: thumbnailData)
                } else {
                    continuation.resume(returning: nil)
                }
            } catch {
                try? FileManager.default.removeItem(at: tempURL)
                continuation.resume(returning: nil)
            }
        }
    }
}
