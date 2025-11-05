//
//  EventFullSheetView.swift
//  EventsApp
//
//  Created by Шоу on 10/28/25.
//

import SwiftUI
import CoreDomain

enum EventAction {
    case watch
    case join
}

struct EventFullSheetView: View {
    let event: EventItem

    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    
    @State private var eventAction: EventAction?  // TODO: Refactor and move to CoreDomain.
    @State private var showActionSheet = false

    private var screenHeight: CGFloat {
        theme.sizes.screenWidth * 1.25
    }

    // Materialized and sorted media items.
    private var sortedMedia: [Media] {
        guard let mediaSet = event.media, !mediaSet.isEmpty else {
            print("EventFullSheetView | Event \(event.name) has no media.")
            return []
        }
        
        let sorted = Array(mediaSet).sorted(by: { $0.position < $1.position })
        
        // Forces materialization of properties and verify files exist.
        for media in sorted {
            let _ = media.id
            let url = media.url
            let _ = media.position
            let _ = media.mimeType
            
            // Verifies the media file exists.
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
        
        print("Displaying \(sorted.count) media items.")
        return sorted
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    // MARK: Media Carousel.
                    ZStack(alignment: .bottom) {
                        if !sortedMedia.isEmpty {
                            MediaCarouselView(
                                mediaItems: sortedMedia,
                                imageWidth: theme.sizes.screenWidth
                            )
                            .frame(width: theme.sizes.screenWidth, height: screenHeight)
                        } else {
                            // Fallback when no media.
                            // TODO: If there is a location, show a full-width map view snapshot here.
                            Rectangle()
                                .fill(Color(hex: event.brandColor) ?? theme.colors.accent)
                                .frame(width: theme.sizes.screenWidth, height: screenHeight)
                        }
                        
                        // MARK: Content Overlay.
                        VStack(alignment: .leading, spacing: theme.spacing.small) {
                            Spacer()

                            HStack {
                                Text(event.name)
                                    .titleStyle()
                                    .lineLimit(2)
                                    .truncationMode(.tail)

                                Spacer()
                            }
                        }
                        .padding(.horizontal, theme.spacing.medium)
                        .padding(.bottom, theme.spacing.medium)
                    }
                    .shadow(radius: theme.spacing.small)
                    
                    // MARK: Event Details:
                    VStack(alignment: .leading, spacing: theme.spacing.medium) {
                        // Date/s & Time/s.
                        if let startTime = event.startTime {
                            HStack(alignment: .center, spacing: theme.spacing.small / 2) {
                                Image(systemName: "calendar")
                                    .bodyTextStyle()
                                
                                Text(startTime.formatted(date: .abbreviated, time: .omitted))
                                    .bodyTextStyle()
                                    .foregroundStyle(theme.colors.accent)
                                
                                Spacer()
                                
                                if !event.isAllDay, let endTime = event.endTime {
                                    Text(startTime.formatted(date: .omitted, time: .shortened) + " - " + endTime.formatted(date: .omitted, time: .shortened))
                                        .bodyTextStyle()
                                } else if !event.isAllDay {
                                    Text(startTime.formatted(date: .omitted, time: .shortened))
                                        .bodyTextStyle()
                                }
                            }
                            .onTapGesture {
                                // TODO: Open Calendar.
                            }
                        }
                        
                        // Location.
                        if let place = event.location {
                            HStack(alignment: .center, spacing: theme.spacing.small / 2) {
                                Image(systemName: "map")
                                    .bodyTextStyle()
                                
                                Text(place.name)
                                    .bodyTextStyle()
                                
                                Spacer()
                                
                                if let address = place.streetAddress {
                                    Text(address)
                                        .bodyTextStyle()
                                }
                            }
                            .onTapGesture {
                                // TODO: Open Apple Maps.
                            }
                        }
                    }
                    .padding([.top, .horizontal], theme.spacing.medium)
                    
                    Divider()
                        .foregroundStyle(theme.colors.surface)
                        .padding(theme.spacing.medium)
                    
                    // Description.
                    if let details = event.details, !details.isEmpty {
                        Text(details)
                            .headlineStyle()
                            .padding(.horizontal, theme.spacing.medium)
                    }

                    Divider()
                        .foregroundStyle(theme.colors.surface)
                        .padding(theme.spacing.medium)

                    // Tags.
                    if let vibes = event.vibes, !vibes.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: theme.spacing.small) {
                                ForEach(Array(vibes), id: \.objectID) { vibe in
                                    Text(vibe.name)
                                        .font(theme.typography.caption)
                                        .foregroundStyle(theme.colors.offText)
                                        .padding(.vertical, theme.spacing.small / 2)
                                        .padding(.horizontal, theme.spacing.small / 2)
                                        .background(
                                            Capsule()
                                                .fill(.clear)
                                                .overlay(
                                                    Capsule()
                                                        .stroke(theme.colors.surface, lineWidth: 1)
                                                )
                                        )
                                }
                            }
                            .padding(.horizontal, theme.spacing.medium)
                        }
                        .padding(.bottom, theme.spacing.large)
                    }
                }
                .padding(.bottom, 100)  // Space for bottom buttons.
            }
            .background(theme.colors.background)
            
            // MARK: RSVP Buttons.
            VStack(spacing: theme.spacing.small) {
                HStack(spacing: theme.spacing.small) {
                    PrimaryButton(title: "Watch", backgroundColor: AnyShapeStyle(theme.colors.surface)) {
                        eventAction = .watch
                        showActionSheet = true
                    }
                    
                    PrimaryButton(title: "Join") {
                        eventAction = .join
                        showActionSheet = true
                    }
                }
            }
            .padding(.horizontal, theme.spacing.medium)
            .padding(.bottom, theme.spacing.small)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        theme.colors.background.opacity(0.80),
                        theme.colors.background
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .sheet(isPresented: $showActionSheet) {
            if let action = eventAction {
                EventActionView(event: event, action: action)
            }
        }
    }
}
