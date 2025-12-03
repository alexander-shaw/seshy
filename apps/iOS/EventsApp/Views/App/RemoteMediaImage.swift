//
//  RemoteMedia.swift
//  EventsApp
//
//  Created by Шоу on 10/12/25.
//

import SwiftUI
import Kingfisher
import CoreData

struct RemoteMediaImage: View {
    let urlString: String
    let targetSize: CGSize
    let media: Media?  // Optional Media object for cloud URL resolution

    @Environment(\.theme) private var theme
    
    // Initializer with just URL string (backward compatibility).
    init(urlString: String, targetSize: CGSize) {
        self.urlString = urlString
        self.targetSize = targetSize
        self.media = nil
    }
    
    // Initializer with Media object (preferred - uses cloud URL).
    init(media: Media, targetSize: CGSize) {
        self.media = media
        self.urlString = media.url
        self.targetSize = targetSize
    }

    // Determine media source - cloud-first strategy.
    private func resolveMediaSource() -> MediaSource {
        // Use MediaURLResolver for consistent resolution logic
        if let media = media {
            return MediaURLResolver.resolveURL(for: media)
        }
        
        // Fallback to URL string parsing
        guard !urlString.isEmpty else { return .missing }
        
        if urlString.hasPrefix("http://") || urlString.hasPrefix("https://"),
           let url = URL(string: urlString) {
            return .remote(url)
        }
        
        return .missing
    }
    
    @ViewBuilder
    var body: some View {
        let source = resolveMediaSource()
        
        switch source {
        case .remote(let remoteURL):
            // Load from cloud - Kingfisher handles caching automatically
            KFImage(remoteURL)
                .placeholder {
                    placeholderImage
                }
                .onFailure { error in
                    print("Failed to load remote URL: \(error.localizedDescription)")
                }
                .setProcessor(ImagePipeline.downsampler(for: targetSize))
                .cacheOriginalImage(false)  // Don't cache original, let Kingfisher manage
                .targetCache(ImagePipeline.cache)
                .fade(duration: 0.25)
                .resizable()
                .scaledToFill()
                .frame(width: targetSize.width, height: targetSize.height)
                .clipped()
        case .missing:
            placeholderImage
        }
    }
    
    private var placeholderImage: some View {
        Rectangle()
            .fill(theme.colors.surface)
            .frame(width: targetSize.width, height: targetSize.height)
    }
}
