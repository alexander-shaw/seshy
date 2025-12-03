//
//  CompactPreview.swift
//  EventsApp
//
//  Created by Шоу on 10/28/25.
//

import SwiftUI
import CoreData

struct CompactPreview: View, Equatable {
    let event: EventItem
    
    @Environment(\.theme) private var theme
    
    static func == (lhs: CompactPreview, rhs: CompactPreview) -> Bool {
        // Only compare event identity, not theme (which is environment)
        lhs.event.objectID == rhs.event.objectID
    }

    private var cardSize: CGFloat {
        theme.sizes.screenWidth / 6
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
    
    // First media item for display
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
        HStack(alignment: .center, spacing: theme.spacing.small) {
            // MARK: Media:
            Group {
                if let mediaItem = firstMediaItem {
                    RemoteMediaImage(
                        media: mediaItem,
                        targetSize: CGSize(width: cardSize, height: cardSize)
                    )
                    .cornerRadius(theme.spacing.small)
                } else {
                    // Fallback:
                    ZStack {
                        RoundedRectangle(cornerRadius: theme.spacing.small)
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
                    .frame(width: cardSize, height: cardSize)
                }
            }
            .shadow(radius: theme.spacing.small)

            VStack(alignment: .leading, spacing: theme.spacing.small / 2) {
                // MARK: Name:
                HStack(spacing: 0) {
                    Text(event.name)
                        .bodyTextStyle()
                        .lineLimit(1)
                        .truncationMode(.tail)

                    Spacer(minLength: 0)
                }

                // MARK: Time:
                let timeText: String = {
                    if event.isAllDay {
                        return "All Day"
                    } else {
                        return EventDateTimeFormatter.calendarTime(for: event.startTime, isAllDay: false)
                    }
                }()

                if !timeText.isEmpty {
                    HStack(alignment: .center, spacing: theme.spacing.small / 2) {
                        Image(systemName: "calendar")
                            .foregroundStyle(theme.colors.offText)
                            .captionTitleStyle()

                        Text(timeText)
                            .foregroundStyle(theme.colors.offText)
                            .captionTextStyle()
                            .lineLimit(1)
                            .truncationMode(.tail)

                        Spacer(minLength: 0)
                    }
                }

                // MARK: Location:
                if let place = event.location {
                    HStack(alignment: .center, spacing: theme.spacing.small / 2) {
                        Image(systemName: "location")
                            .foregroundStyle(theme.colors.offText)
                            .captionTitleStyle()

                        Text(place.name)
                            .foregroundStyle(theme.colors.offText)
                            .captionTextStyle()
                            .lineLimit(1)
                            .truncationMode(.tail)

                        Spacer(minLength: 0)
                    }
                }
            }

            Spacer()

            // MANAGE
            // EDIT
            // SHARE
            // RATE
            // CANCEL
            // REQUEST REFUND
            // REPORT
            Menu {
                Button(action: {
                    handleManageGuests()
                }) {
                    HStack {
                        Image(systemName: "person.3.sequence")
                            .bodyTextStyle()
                        Text("Manage Guests")
                            .bodyTextStyle()
                    }
                }

                Button(action: {
                    handleEdit()
                }) {
                    HStack {
                        Image(systemName: "square.and.pencil")
                            .bodyTextStyle()
                        Text("Edit")
                            .bodyTextStyle()
                    }
                }

                Button(action: {
                    handleShareLink()
                }) {
                    HStack {
                        Image(systemName: "link")
                            .bodyTextStyle()
                        Text("Share Link")
                            .bodyTextStyle()
                    }
                }

                Button(action: {
                    handleRate()
                }) {
                    HStack {
                        Image(systemName: "star")
                            .bodyTextStyle()
                        Text("Rate")
                            .bodyTextStyle()
                    }
                }

                Button(action: {
                    handleCancel()
                }) {
                    HStack {
                        Image(systemName: "trash")
                            .bodyTextStyle()
                        Text("Cancel")
                            .bodyTextStyle()
                    }
                }

                Button(action: {
                    handleRequestRefund()
                }) {
                    HStack {
                        Image(systemName: "arrow.uturn.left")
                            .bodyTextStyle()
                        Text("Request Refund")
                            .bodyTextStyle()
                    }
                }

                Button(action: {
                    handleReport()
                }) {
                    HStack {
                        Image(systemName: "exclamationmark.bubble")
                            .bodyTextStyle()
                        Text("Report")
                            .bodyTextStyle()
                    }
                }
            } label: {
                IconButton(icon: "ellipsis", style: .secondary) {}
            }
        }
        .padding(.horizontal, theme.spacing.medium)
    }
    
    // MARK: - Menu Actions
    
    private func handleEdit() {
        // TODO: Implement edit action
        print("Edit tapped for event: \(event.name)")
    }
    
    private func handleCancel() {
        // TODO: Implement cancel action
        print("Cancel tapped for event: \(event.name)")
    }
    
    private func handleRequestRefund() {
        // TODO: Implement request refund action
        print("Request Refund tapped for event: \(event.name)")
    }
    
    private func handleShareLink() {
        // TODO: Implement share link action
        print("Share Link tapped for event: \(event.name)")
    }
    
    private func handleRate() {
        // TODO: Implement rate action
        print("Rate tapped for event: \(event.name)")
    }
    
    private func handleReport() {
        // TODO: Implement report action
        print("Report tapped for event: \(event.name)")
    }
    
    private func handleManageGuests() {
        // TODO: Implement manage guests action
        print("Manage Guests tapped for event: \(event.name)")
    }
}
