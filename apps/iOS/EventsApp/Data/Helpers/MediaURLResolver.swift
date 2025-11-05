//
//  MediaURLResolver.swift
//  EventsApp
//
//  Created by Шоу on 10/29/25.
//

import Foundation
import CoreData
import CoreDomain

// Resolves media source (local file, remote URL, or missing).
// Implements local-first strategy: checks for local file before falling back to remote.
public enum MediaSource {
    case local(URL)
    case remote(URL)
    case missing
}

// Helper for resolving media URLs with local-first strategy.
public enum MediaURLResolver {
    
    // Resolves the media source (local file preferred, remote fallback).
    // Returns: MediaSource indicating local file, remote URL, or missing.
    public static func resolveURL(for media: Media) -> MediaSource {
        let urlString = media.url
        
        // Empty URL means missing.
        guard !urlString.isEmpty else {
            print("Empty URL for media \(media.id)")
            return .missing
        }
        
        // DEBUG: Print what we are checking.
        print("Resolving URL for media \(media.id): '\(urlString)'")
        
        // Check if it's a file URL (starts with file:// or is a local path).
        if urlString.hasPrefix("file://") || (!urlString.hasPrefix("http://") && !urlString.hasPrefix("https://")) {
            // Try to construct file URL.
            let fileURL: URL
            if urlString.hasPrefix("file://") {
                if let url = URL(string: urlString) {
                    fileURL = url
                } else {
                    // Parse manually by removing file:// prefix.
                    let path = String(urlString.dropFirst(7))
                    fileURL = URL(fileURLWithPath: path)
                }
            } else {
                // Treat as file path.
                fileURL = URL(fileURLWithPath: urlString)
            }
            
            print("Constructed file URL:  \(fileURL.path)")
            print("File exists check:  \(MediaStorageHelper.mediaFileExists(at: fileURL))")

            // Check if local file exists.
            if MediaStorageHelper.mediaFileExists(at: fileURL) {
                print("Found local file: \(fileURL.path)")
                return .local(fileURL)
            } else {
                // File URL but does not exist - try to find it by media ID as fallback.
                let expectedFileURL = MediaStorageHelper.getMediaFileURL(mediaID: media.id, isVideo: media.isVideo)
                print("Expected file URL (by ID): \(expectedFileURL.path)")
                
                if MediaStorageHelper.mediaFileExists(at: expectedFileURL) {
                    print("Found file at expected location (by ID): \(expectedFileURL.path)")
                    // Also check if we need to update the URL in Core Data to match.
                    // Do not do this here as it would require async context - just use the found file.
                    return .local(expectedFileURL)
                }
                
                // Try normalizing the path (remove file:// prefix and check).
                let normalizedPath = urlString.hasPrefix("file://") ? String(urlString.dropFirst(7)) : urlString
                let normalizedFileURL = URL(fileURLWithPath: normalizedPath)
                print("Trying normalized path: \(normalizedFileURL.path)")
                if MediaStorageHelper.mediaFileExists(at: normalizedFileURL) {
                    print("Found file at normalized path: \(normalizedFileURL.path)")
                    return .local(normalizedFileURL)
                }
                
                print("File not found at:")
                print(" - Original:  \(fileURL.path)")
                print(" - Expected (by ID):  \(expectedFileURL.path)")
                print(" - Normalized:  \(normalizedFileURL.path)")
                return .missing
            }
        } else {
            // Remote HTTPS URL.
            if let remoteURL = URL(string: urlString) {
                print("Remote URL:  \(remoteURL)")
                return .remote(remoteURL)
            } else {
                print("Invalid remote URL:  \(urlString)")
                return .missing
            }
        }
    }
    
    // Constructs a remote URL from media ID (for future cloud storage integration).
    // Parameters:
    //  - mediaID: The media UUID.
    //  - isVideo: Whether it is a video.
    // Returns: Remote URL.
    // Note: This would be replaced with actual cloud storage URL construction.
    private static func constructRemoteURL(mediaID: UUID, isVideo: Bool) -> URL? {
        // TODO: Replace with actual cloud storage URL.
        // Example: "https://storage.example.com/media/\(mediaID.uuidString).\(isVideo ? "mp4" : "jpg")"
        return nil
    }
}
