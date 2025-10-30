//
//  RemoteMedia.swift
//  EventsApp
//
//  Created by Шоу on 10/12/25.
//

import SwiftUI
import Kingfisher
import CoreData
import CoreDomain

struct RemoteMediaImage: View {
    let urlString: String
    let targetSize: CGSize  // The actual size the image will render at.
    let media: Media?  // Optional Media object for local-first resolution.

    @Environment(\.theme) private var theme
    
    // Initializer with just URL string (backward compatibility).
    init(urlString: String, targetSize: CGSize) {
        self.urlString = urlString
        self.targetSize = targetSize
        self.media = nil
    }
    
    // Initializer with Media object (preferred - uses local-first resolution).
    init(media: Media, targetSize: CGSize) {
        self.media = media
        self.urlString = media.url
        self.targetSize = targetSize
    }

    // Determine media source using improved Media model properties.
    private func resolveMediaSource() -> MediaSource {
        guard let media = media else {
            // Fallback to URL string parsing (backward compatibility).
            return legacySourceFromURL()
        }
        
        // Force materialization before resolving.
        let _ = media.id
        let _ = media.url
        let _ = media.mimeType
        
        // Use the improved actualFileURL property.
        if let localFileURL = media.actualFileURL {
            return .local(localFileURL)
        }
        
        // Check for remote URL.
        if let remoteURL = media.remoteURL {
            return .remote(remoteURL)
        }
        
        // Media is missing.
        return .missing
    }
    
    private func legacySourceFromURL() -> MediaSource {
        if urlString.hasPrefix("file://") || (!urlString.hasPrefix("http://") && !urlString.hasPrefix("https://")) {
            if let fileURL = constructFileURL(from: urlString),
               FileManager.default.fileExists(atPath: fileURL.path) {
                return .local(fileURL)
            }
        } else if let url = URL(string: urlString), url.scheme?.hasPrefix("http") == true {
            return .remote(url)
        }
        return .missing
    }
    
    @ViewBuilder
    var body: some View {
        let source = resolveMediaSource()
        
        switch source {
            case .local(let fileURL):
                let _ = print("Loading LOCAL file:  \(fileURL.path)")
                KFImage(source: .provider(LocalFileImageDataProvider(fileURL: fileURL)))
                    .placeholder {
                        placeholderImage
                    }
                    .onFailure { error in
                        print("Failed to load local file:  \(error.localizedDescription)")
                    }
                    .setProcessor(ImagePipeline.downsampler(for: targetSize))
                    .cacheOriginalImage(true)  // Cache local files for faster access.
                    .targetCache(ImagePipeline.cache)
                    .fade(duration: 0.25)
                    .resizable()
                    .scaledToFill()
                    .frame(width: targetSize.width, height: targetSize.height)
                    .clipped()
            case .remote(let remoteURL):
                let _ = print("Loading REMOTE URL:  \(remoteURL)")
                KFImage(remoteURL)
                    .placeholder {
                        placeholderImage
                    }
                    .onFailure { error in
                        print("Failed to load remote URL:  \(error.localizedDescription)")
                    }
                    .setProcessor(ImagePipeline.downsampler(for: targetSize))
                    .cacheOriginalImage(false)
                    .targetCache(ImagePipeline.cache)
                    .fade(duration: 0.25)
                    .resizable()
                    .scaledToFill()
                    .frame(width: targetSize.width, height: targetSize.height)
                    .clipped()
            case .missing:
                let _ = print("Media source is MISSING; showing placeholder.")
                placeholderImage
        }
    }
    
    @ViewBuilder
    private var legacyURLResolution: some View {
        // Check if it's a file URL (starts with file:// or is a local path).
        if urlString.hasPrefix("file://") || (!urlString.hasPrefix("http://") && !urlString.hasPrefix("https://")) {
            // Local file URL: use LocalFileImageDataProvider.
            Group {
                if let fileURL = constructFileURL(from: urlString) {
                    KFImage(source: .provider(LocalFileImageDataProvider(fileURL: fileURL)))
                        .setProcessor(ImagePipeline.downsampler(for: targetSize))
                        .cacheOriginalImage(true)
                        .targetCache(ImagePipeline.cache)
                        .fade(duration: 0.25)
                        .resizable()
                        .scaledToFill()
                        .clipped()
                        .redacted(reason: .placeholder)
                } else {
                    placeholderImage
                }
            }
        } else if let url = URL(string: urlString), url.scheme?.hasPrefix("http") == true {
            // Remote HTTPS URL.
            KFImage(url)
                .setProcessor(ImagePipeline.downsampler(for: targetSize))
                .cacheOriginalImage(false)
                .targetCache(ImagePipeline.cache)
                .fade(duration: 0.25)
                .resizable()
                .scaledToFill()
                .clipped()
                .redacted(reason: .placeholder)
        } else {
            placeholderImage
        }
    }
    
    private var placeholderImage: some View {
        Rectangle()
            .fill(theme.colors.surface)
            .frame(width: targetSize.width, height: targetSize.height)
//            .overlay {
//                Image(systemName: "photo")
//                    .resizable()
//                    .scaledToFit()
//                    .foregroundStyle(theme.colors.offText.opacity(0.5))
//                    .frame(width: min(targetSize.width, targetSize.height) * 0.2)
//            }
    }
    
    private func constructFileURL(from urlString: String) -> URL? {
        if urlString.hasPrefix("file://") {
            if let url = URL(string: urlString) {
                return url
            }
            let path = String(urlString.dropFirst(7))
            return URL(fileURLWithPath: path)
        } else {
            return URL(fileURLWithPath: urlString)
        }
    }
}
