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
                // Placeholder when no media; show rectangle fallback.
                Rectangle()
                    .fill(theme.colors.surface)
                    .frame(width: imageWidth, height: imageHeight)
            } else {
                // Carousel of media items.
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
                // Bottom blur gradient to improve text/dot contrast.
                .overlay(alignment: .bottom) {
                    LinearGradient(
                        gradient: Gradient(colors: [.clear, theme.colors.background.opacity(0.80)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: imageHeight / 3)
                    .frame(maxWidth: .infinity, alignment: .bottom)
                    .clipped()
                }
                .overlay {
                    // Transparent tap zones overlay: left half -> previous, right half -> next.
                    GeometryReader { geo in
                        Color.clear
                            .contentShape(Rectangle())
                            .simultaneousGesture(
                                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                                    .onEnded { value in
                                        // Treat as a tap only if movement is tiny to avoid
                                        // interfering with sheet dismissal (vertical drags).
                                        let translation = value.translation
                                        let movementMagnitude = sqrt(translation.width * translation.width + translation.height * translation.height)
                                        let tapMovementThreshold: CGFloat = 10
                                        guard movementMagnitude <= tapMovementThreshold else {
                                            return
                                        }

                                        let width = geo.size.width
                                        let tappedLeft = value.startLocation.x < width / 2
                                        if tappedLeft {
                                            if currentIndex > 0 {
                                                currentIndex -= 1
                                            }
                                        } else {
                                            if currentIndex < mediaItems.count - 1 {
                                                currentIndex += 1
                                            }
                                        }
                                    }
                            )
                    }
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
                
                // MARK: Indicator Dots:
                // Only show if more than 1 item.
                if mediaItems.count > 1 {
                    VStack {
                        Spacer()

                        // TODO: Replace theme.colors.accent with event.brandColor.
                        HStack(spacing: theme.spacing.small / 2) {
                            ForEach(0..<mediaItems.count, id: \.self) { index in
                                Circle()
                                    .frame(width: currentIndex == index ? 6 : 4, height: currentIndex == index ? 6 : 4)
                                    .foregroundStyle(currentIndex == index ? theme.colors.mainText : theme.colors.offText)
                                    .animation(.easeInOut(duration: 0.2), value: currentIndex)
                            }
                        }
                        .padding(.vertical, theme.spacing.small / 2)
                        .padding(.horizontal, theme.spacing.small)
                        .background(theme.colors.surface)
                        .clipShape(Capsule())
                        .padding(.bottom, theme.spacing.small)
                    }
                }
            }
        }
        .frame(width: imageWidth, height: imageHeight)
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
            .overlay(alignment: .center) {
                // MARK: Video Play Indicator.
                if media.isVideo {
                    Image(systemName: "play.circle.fill")
                        .iconStyle()
                }
            }
        }
        .frame(width: targetSize.width, height: targetSize.height)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .contentShape(Rectangle())
        .onAppear {
            print("Displaying media \(media.id); URL:  \(media.url); mimeType:  \(media.mimeType ?? "nil")")
        }
    }
}
