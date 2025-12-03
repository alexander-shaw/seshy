//
//  EventCardPreview.swift
//  EventsApp
//
//  Created by Auto on 12/6/24.
//

import SwiftUI
import CoreData

enum CardSize {
    case smallCard
    case bigCard
}

struct EventCardPreview: View {
    let event: EventItem
    let cardSize: CardSize

    @Environment(\.theme) private var theme
    
    private var cardSizeValue: CGFloat {
        switch cardSize {
            case .smallCard:
            return theme.sizes.screenWidth / 2.5
            case .bigCard:
                return theme.sizes.screenWidth
        }
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
                case .remote(let remoteURL):
                    print("Media \(media.id) - Remote URL:  \(remoteURL)")
                case .missing:
                    print("Media \(media.id) - FILE MISSING! URL:  \(url)")
            }
        }
        
        print("Event \(event.name) has \(sorted.count) media items.")
        return sorted
    }
    
    // First media item for display.
    private var firstMediaItem: Media? {
        let media = sortedMedia.first(where: { !$0.url.isEmpty })
        if let media = media {
            let source = MediaURLResolver.resolveURL(for: media)
            switch source {
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
        VStack(alignment: .leading, spacing: theme.spacing.small) {
            Group {
                if let mediaItem = firstMediaItem {
                    RemoteMediaImage(
                        media: mediaItem,
                        targetSize: CGSize(width: cardSizeValue, height: cardSizeValue / (5 / 4))
                    )
                    .clipShape(RoundedRectangle(cornerRadius: cardSize == .smallCard ? theme.spacing.small : 0, style: .continuous))
                } else {
                    // Fallback:
                    ZStack {
                        RoundedRectangle(cornerRadius: cardSize == .smallCard ? theme.spacing.small : 0, style: .continuous)
                            .fill(theme.colors.surface)

                        // Bottom Blur Gradient.
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
                        }
                    }
                }
            }
            .frame(width: cardSizeValue, height: cardSizeValue / (5 / 4))
            .clipped()
            .shadow(radius: cardSize == .smallCard ? theme.spacing.small / 2 : theme.spacing.small)

            VStack(alignment: .leading, spacing: theme.spacing.small / 2) {
                Text(event.name)
                    .bodyTextStyle()
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(1)
                    .truncationMode(.tail)

                if let startTime = event.startTime {
                    HStack(alignment: .center, spacing: theme.spacing.small / 2) {
                        Image(systemName: "calendar")
                            .foregroundStyle(theme.colors.offText)
                            .captionTitleStyle()

                        Text(EventDateTimeFormatter.cardPreview(for: startTime, isAllDay: event.isAllDay))
                            .foregroundStyle(theme.colors.offText)
                            .captionTextStyle()
                            .lineLimit(1)
                            .truncationMode(.tail)

                        Spacer(minLength: 0)
                    }
                }

                if let place = event.location {
                    HStack(alignment: .center, spacing: theme.spacing.small / 2) {
                        Image(systemName: "location")
                            .foregroundStyle(theme.colors.offText)
                            .captionTitleStyle()

                        // TODO: If public/joined, then name.  If private/not invited, then distance in ft/mi.
                        Text(place.name)
                            .foregroundStyle(theme.colors.offText)
                            .captionTextStyle()
                            .lineLimit(1)
                            .truncationMode(.tail)

                        Spacer(minLength: 0)
                    }
                }
            }
            .padding(.horizontal, cardSize == .smallCard ? 0 : theme.spacing.medium)
            .frame(width: cardSizeValue)
        }
    }
}
