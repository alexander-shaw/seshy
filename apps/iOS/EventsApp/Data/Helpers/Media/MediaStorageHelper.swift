//
//  MediaStorageHelper.swift
//  EventsApp
//
//  Created by Шоу on 10/29/25.
//

import Foundation
import UIKit

// MARK: - Deprecated
// This helper is deprecated. Media is now stored in cloud storage.
// Local file storage is no longer used - Kingfisher handles caching automatically.
// Kept for backward compatibility with legacy data only.

// Helper for managing persistent media file storage.
// Files are saved to Documents/Media/ directory for persistence across app restarts.
@available(*, deprecated, message: "Media is now stored in cloud. Use MediaUploadService for uploads. Kingfisher handles caching.")
public enum MediaStorageHelper {
    
    // MARK: Directory Management:
    private static var mediaDirectory: URL {
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let mediaDir = documentsDir.appendingPathComponent("Media", isDirectory: true)
        
        // Create directory if it doesn't exist.
        if !FileManager.default.fileExists(atPath: mediaDir.path) {
            try? FileManager.default.createDirectory(at: mediaDir, withIntermediateDirectories: true)
        }
        
        return mediaDir
    }
    
    private static var imagesDirectory: URL {
        let url = mediaDirectory.appendingPathComponent("images", isDirectory: true)
        
        // Create subdirectory if it doesn't exist.
        if !FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
        
        return url
    }
    
    // MARK: Save Media
    // Saves image data to persistent storage.
    // Parameters:
    //  - data: The image data to save.
    //  - mediaID: Unique identifier for the media item.
    // Returns: The file URL where the media was saved.
    // Throws: File system errors.
    public static func saveMediaData(_ data: Data, mediaID: UUID, isVideo: Bool = false) throws -> URL {
        let subdir = imagesDirectory
        let fileExtension = "jpg"
        let fileName = "\(mediaID.uuidString).\(fileExtension)"
        let fileURL = subdir.appendingPathComponent(fileName)
        
        print("Saving image to: \(fileURL.path)")
        print("File URL (absoluteString): \(fileURL.absoluteString)")
        print("Data size: \(data.count) bytes")
        
        // Ensure directory exists.
        try FileManager.default.createDirectory(at: subdir, withIntermediateDirectories: true, attributes: nil)
        
        try data.write(to: fileURL, options: .atomic)
        
        // Verify write succeeded.
        if FileManager.default.fileExists(atPath: fileURL.path) {
            let fileSize = try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? Int
            print("File saved successfully. Size: \(fileSize ?? 0) bytes at: \(fileURL.path)")
            print("File will be stored in Core Data as: \(fileURL.absoluteString)")
        } else {
            print("File NOT found after write at: \(fileURL.path)")
            throw NSError(domain: "MediaStorageHelper", code: -1, userInfo: [NSLocalizedDescriptionKey: "File was not created after write operation"])
        }
        
        return fileURL
    }
    
    // MARK: Retrieve Media
    // Gets the expected file URL for a media item (does not check existence).
    // Parameters:
    //  - mediaID: Unique identifier for the media item.
    //  - isVideo: Whether this is a video file (kept for backward compatibility, ignored).
    // Returns: The expected file URL.
    public static func getMediaFileURL(mediaID: UUID, isVideo: Bool = false) -> URL {
        let subdir = imagesDirectory
        let fileExtension = "jpg"
        let fileName = "\(mediaID.uuidString).\(fileExtension)"
        return subdir.appendingPathComponent(fileName)
    }
    
    // Checks if a media file exists at the given URL.
    // - Parameter url: The file URL to check.
    // - Returns: True if the file exists.  Else, false.
    public static func mediaFileExists(at url: URL) -> Bool {
        return FileManager.default.fileExists(atPath: url.path)
    }
    
    // MARK: Delete Media
    // Deletes a media file from storage.
    // - Parameter url: The file URL to delete.
    // - Throws: File system errors but tolerates file not existing.
    public static func deleteMediaFile(at url: URL) throws {
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
    }
    
    // Deletes a media file by ID.
    // Parameters:
    //  - mediaID: The media ID.
    //  - isVideo: Whether it is a video (kept for backward compatibility, ignored).
    // Throws: File system errors.
    public static func deleteMediaFile(mediaID: UUID, isVideo: Bool = false) throws {
        let url = getMediaFileURL(mediaID: mediaID, isVideo: isVideo)
        try deleteMediaFile(at: url)
    }
}
