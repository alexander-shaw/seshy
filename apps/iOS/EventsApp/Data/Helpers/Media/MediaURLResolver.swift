//
//  MediaURLResolver.swift
//  EventsApp
//
//  Created by Шоу on 10/29/25.
//

import Foundation
import CoreData

// Resolves media source (remote URL or missing).
// Cloud-first strategy: all media is stored in cloud, Kingfisher handles caching.
public enum MediaSource {
    case remote(URL)
    case missing
}

// Helper for resolving media URLs with cloud-first strategy.
public enum MediaURLResolver {
    
    // Resolves the media source (cloud URL only).
    // Returns: MediaSource indicating remote URL or missing.
    // Kingfisher automatically handles caching for offline access.
    public static func resolveURL(for media: Media) -> MediaSource {
        let urlString = media.url
        
        // Empty URL means missing.
        guard !urlString.isEmpty else {
            return .missing
        }
        
        // Check if it's a remote URL (http/https).
        if urlString.hasPrefix("http://") || urlString.hasPrefix("https://") {
            if let remoteURL = URL(string: urlString) {
                return .remote(remoteURL)
            }
        }
        
        // Invalid or non-remote URL - treat as missing.
        // Legacy file:// URLs will be treated as missing (expected for old data).
        return .missing
    }
}
