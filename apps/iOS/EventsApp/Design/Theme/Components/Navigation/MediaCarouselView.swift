//
//  MediaCarouselView.swift
//  EventsApp
//
//  Created by Шоу on 1/25/25.
//

import SwiftUI

struct MediaCarouselView: View {
    let mediaItems: [Media]
    let imageWidth: CGFloat
    let imageHeight: CGFloat?
    
    @Environment(\.theme) private var theme
    @State private var currentIndex: Int = 0
    
    init(mediaItems: [Media], imageWidth: CGFloat, imageHeight: CGFloat? = nil) {
        self.mediaItems = mediaItems
        self.imageWidth = imageWidth
        self.imageHeight = imageHeight
    }
    
    private var computedImageHeight: CGFloat {
        imageHeight ?? (imageWidth * 5 / 4)
    }
    
    private var capsuleWidth: CGFloat {
        guard mediaItems.count > 0 else { return 0 }
        let n = CGFloat(mediaItems.count)
        return (imageWidth - (n + 1) * theme.spacing.small) / n
    }
    
    var body: some View {
        ZStack {
            // Animated gradient background based on current media
            if !mediaItems.isEmpty && currentIndex < mediaItems.count {
                let currentMedia = mediaItems[currentIndex]
                let gradientColors = mediaGradientColors(for: currentMedia)
                
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: imageWidth, height: computedImageHeight)
                    .animation(.easeInOut(duration: 0.3), value: currentIndex)
            } else {
                // Fallback background
                Rectangle()
                    .fill(theme.colors.surface)
                    .frame(width: imageWidth, height: computedImageHeight)
            }
            
            if mediaItems.isEmpty {
                // Placeholder when no media; show rectangle fallback.
                Rectangle()
                    .fill(theme.colors.surface)
                    .frame(width: imageWidth, height: computedImageHeight)
            } else {
                // Carousel of media items.
                TabView(selection: $currentIndex) {
                    ForEach(0..<mediaItems.count, id: \.self) { index in
                        MediaItemView(media: mediaItems[index], targetSize: CGSize(width: imageWidth, height: computedImageHeight))
                            .tag(index)
                            .frame(width: imageWidth, height: computedImageHeight)
                            .clipped()
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .frame(width: imageWidth, height: computedImageHeight)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                // Bottom blur gradient to improve text/dot contrast.
                .overlay(alignment: .bottom) {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            .clear,
                            theme.colors.background.opacity(0.80)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: computedImageHeight / 3)
                    .frame(maxWidth: .infinity, alignment: .bottom)
                    .clipped()
                }
                .overlay {
                    // Tap-only zones: do not install drag gestures so swipes pass to TabView/sheet.
                    HStack(spacing: 0) {
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if currentIndex > 0 {
                                    currentIndex -= 1
                                }
                            }
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if currentIndex < mediaItems.count - 1 {
                                    currentIndex += 1
                                }
                            }
                    }
                    .hapticFeedback(.light)
                }
                .onChange(of: mediaItems.count) { _, newCount in
                    if newCount > 0 && currentIndex >= newCount {
                        currentIndex = 0
                    } else if newCount == 0 {
                        currentIndex = 0
                    }
                }
                .onAppear {
                    // Reset to first item when view appears.
                    if !mediaItems.isEmpty {
                        currentIndex = 0
                    }
                }
                
                // MARK: Capsule Indicators:
                // Only show if more than 1 item.
                if mediaItems.count > 1 {
                    VStack {
                        HStack(spacing: theme.spacing.small) {
                            ForEach(0..<mediaItems.count, id: \.self) { index in
                                Capsule()
                                    .frame(width: capsuleWidth, height: theme.spacing.small / 3)
                                    .foregroundStyle(currentIndex == index ? theme.colors.mainText : theme.colors.offText)
                                    .animation(.easeInOut(duration: 0.2), value: currentIndex)
                            }
                        }
                        .padding([.top, .horizontal], theme.spacing.small)

                        Spacer()
                    }
                }
            }
        }
        .frame(width: imageWidth, height: computedImageHeight)
    }
    
    // MARK: - Helper Methods
    
    /// Gets gradient colors for a media item, with fallback for legacy media
    private func mediaGradientColors(for media: Media) -> [Color] {
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
        
        // Fallback to theme surface color
        return [theme.colors.surface, theme.colors.surface.opacity(0.8)]
    }
}

struct MediaItemView: View {
    let media: Media
    let targetSize: CGSize
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        Group {
            // Force materialization of media properties before resolving.
            let _ = {
                let _ = media.id
                let _ = media.url
                let _ = media.mimeType
                return true
            }()
            
            RemoteMediaImage(
                media: media,
                targetSize: targetSize
            )
        }
        .frame(width: targetSize.width, height: targetSize.height)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .contentShape(Rectangle())
        .onAppear {
            print("Displaying media \(media.id) and URL:  \(media.url) and mimeType:  \(media.mimeType ?? "nil").")
        }
    }
}
