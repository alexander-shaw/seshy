//
//  EventPreview.swift
//  EventsApp
//
//  Created by Шоу on 10/28/25.
//

import SwiftUI
import CoreData
import CoreDomain

struct EventPreview: View {
    let event: EventItem
    
    @Environment(\.theme) private var theme

    private var screenHeight: CGFloat {
        theme.sizes.screenWidth * 1.33
    }

    // Materialized and sorted media items.
    private var sortedMedia: [Media] {
        // Access the media relationship to force fault resolution.
        guard let mediaSet = event.media, !mediaSet.isEmpty else {
            print("Event \(event.name) has no media.")
            return []
        }
        
        let sorted = Array(mediaSet).sorted(by: { $0.position < $1.position })
        
        // Force materialization of properties and verify files exist.
        for media in sorted {
            let _ = media.id
            let url = media.url
            let _ = media.position
            let _ = media.mimeType
            
            // Verify the media file exists.
            let source = MediaURLResolver.resolveURL(for: media)
            switch source {
            case .local(let fileURL):
                print("Media \(media.id) - Local file exists:  \(fileURL.path)")
            case .remote:
                print("Media \(media.id) - Remote URL:  \(url)")
            case .missing:
                print("Media \(media.id) - FILE MISSING! URL:  \(url)")
            }
        }
        
        print("Event \(event.name) has \(sorted.count) media items.")
        return sorted
    }
    
    // First media item for display
    private var firstMedia: Media? {
        let media = sortedMedia.first(where: { !$0.url.isEmpty })
        if let media = media {
            let source = MediaURLResolver.resolveURL(for: media)
            switch source {
                case .local(let fileURL):
                    print("Displaying first media (LOCAL): \(media.id) and file:  \(fileURL.path)")
                case .remote(let url):
                    print("Displaying first media (REMOTE): \(media.id) and URL:  \(url)")
                case .missing:
                    print("First media FILE MISSING: \(media.id) and stored URL:  \(media.url)")
            }
        } else {
            print("No valid media found (all have empty URLs).")
        }
        return media
    }

    var body: some View {
        ZStack(alignment: .center) {
            // MARK: Background Media (Or Fallback):
            Group {
                if let media = firstMedia {
                    RemoteMediaImage(
                        media: media,
                        targetSize: CGSize(width: theme.sizes.screenWidth, height: screenHeight)
                    )
                } else {
                    // Fallback rectangle when no media.
                    Rectangle()
                        .fill(theme.colors.surface)
                        .frame(width: theme.sizes.screenWidth, height: screenHeight)
                }
            }

            // MARK: Bottom Blur Gradient.
            VStack {
                Spacer()
                
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        theme.colors.background.opacity(0.80)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: screenHeight / 3)
            }
            
            // MARK: Content Overlay.
            VStack(alignment: .leading, spacing: theme.spacing.small) {
                Spacer()
                
                // Event Name.
                HStack(alignment: .bottom, spacing: theme.spacing.medium) {
                    Spacer()

                    Text(event.name)
                        .titleStyle()
                        .lineLimit(2)
                        .truncationMode(.tail)

                    Spacer()
                }
                .padding(.horizontal, theme.spacing.medium)
                .padding(.bottom, theme.spacing.small)

                // Location and Time.
                HStack(alignment: .center, spacing: theme.spacing.small / 2) {
                    Spacer()

                    if let place = event.location {
                        Image(systemName: "location")
                            .foregroundStyle(theme.colors.mainText)
                            .captionTitleStyle()

                        Text(place.name)
                            .foregroundStyle(theme.colors.mainText)
                            .captionTextStyle()
                    }

                    if let place = event.location, let startTime = event.startTime {
                        Text("•")
                            .foregroundStyle(theme.colors.mainText)
                            .captionTitleStyle()
                    }

                    if let startTime = event.startTime {
                        Image(systemName: "calendar")
                            .foregroundStyle(theme.colors.mainText)
                            .captionTitleStyle()

                        Text(startTime.formatted(date: .abbreviated, time: .omitted))
                            .foregroundStyle(theme.colors.mainText)
                            .captionTextStyle()
                    }

                    Spacer()
                }
                .padding([.horizontal, .bottom], theme.spacing.medium)
            }
        }
        // .cornerRadius(12)
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
    }
}
