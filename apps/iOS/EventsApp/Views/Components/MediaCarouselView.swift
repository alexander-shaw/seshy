//
//  MediaCarouselView.swift
//  EventsApp
//
//  Created by Шоу on 1/25/25.
//

import SwiftUI
import CoreDomain

struct MediaCarouselView: View {
    let mediaItems: [Media]
    let imageWidth: CGFloat
    
    @Environment(\.theme) private var theme
    @State private var currentIndex: Int = 0
    
    private var imageHeight: CGFloat {
        imageWidth * 5 / 4
    }
    
    var body: some View {
        ZStack {
            // Background color.
            Rectangle()
                .fill(theme.colors.surface)
                .frame(width: imageWidth, height: imageHeight)
            
            if mediaItems.isEmpty {
                // Placeholder when no media - show rectangle fallback
                Rectangle()
                    .fill(theme.colors.surface)
                    .frame(width: imageWidth, height: imageHeight)
                    .overlay {
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(theme.colors.offText.opacity(0.5))
                            .frame(width: imageWidth * 0.20, height: imageWidth * 0.20)
                    }
            } else {
                // Carousel of media items
                TabView(selection: $currentIndex) {
                    ForEach(0..<mediaItems.count, id: \.self) { index in
                        MediaItemView(media: mediaItems[index], targetSize: CGSize(width: imageWidth, height: imageHeight))
                            .tag(index)
                            .frame(width: imageWidth, height: imageHeight)
                            .clipped()
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .frame(width: imageWidth, height: imageHeight)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onChange(of: mediaItems.count) { _, newCount in
                    if newCount > 0 && currentIndex >= newCount {
                        currentIndex = 0
                    } else if newCount == 0 {
                        currentIndex = 0
                    }
                }
                .onAppear {
                    // Reset to first item when view appears
                    if !mediaItems.isEmpty {
                        currentIndex = 0
                    }
                }
                
                // Custom indicator dots (only show if more than 1 item)
                if mediaItems.count > 1 {
                    VStack {
                        Spacer()
                        HStack(spacing: 6) {
                            ForEach(0..<mediaItems.count, id: \.self) { index in
                                Circle()
                                    .frame(width: currentIndex == index ? 6 : 4,
                                           height: currentIndex == index ? 6 : 4)
                                    .foregroundStyle(currentIndex == index ? theme.colors.accent : theme.colors.offText.opacity(0.5))
                                    .animation(.easeInOut(duration: 0.2), value: currentIndex)
                            }
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 6)
                        .background(theme.colors.surface.opacity(0.8))
                        .clipShape(Capsule())
                        .padding(.bottom, 12)
                    }
                    
                    // Count indicator
                    VStack {
                        HStack {
                            Spacer()
                            Text("\(currentIndex + 1) / \(mediaItems.count)")
                                .font(theme.typography.caption)
                                .foregroundStyle(theme.colors.offText)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(theme.colors.surface.opacity(0.8))
                                .clipShape(Capsule())
                                .padding(.top, 12)
                                .padding(.trailing, 12)
                        }
                        Spacer()
                    }
                }
            }
        }
        .frame(width: imageWidth, height: imageHeight)
    }
}

// MARK: - Media Item View
struct MediaItemView: View {
    let media: Media
    let targetSize: CGSize
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        Group {
            // Force materialization of media properties before resolving
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
            .overlay(alignment: .center) {
                if media.isVideo {
                    // Video play indicator
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
        }
        .frame(width: targetSize.width, height: targetSize.height)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .contentShape(Rectangle())
        .onAppear {
            print("🖼️ [MediaItemView] Displaying media \(media.id), URL: '\(media.url)', mimeType: '\(media.mimeType ?? "nil")'")
        }
    }
}

#Preview {
    MediaCarouselView(
        mediaItems: [],
        imageWidth: UIScreen.main.bounds.width
    )
}

