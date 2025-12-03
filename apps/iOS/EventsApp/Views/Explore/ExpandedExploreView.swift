//
//  ExpandedExploreView.swift
//  EventsApp
//
//  Created by Шоу on 10/25/25.
//

import SwiftUI

// Full-screen view showing all events for a specific Discover section.
struct ExpandedExploreView: View {
    let section: DiscoverSection
    let events: [EventItem]
    let onEventTap: (EventItem) -> Void
    
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedEvent: EventItem?
    
    var body: some View {
        VStack(spacing: 0) {
            if events.isEmpty {
                VStack {
                    Spacer()
                    Text("No events found :(")
                        .foregroundStyle(theme.colors.offText)
                        .bodyTextStyle()
                    Spacer()
                }
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: theme.spacing.medium) {
                        ForEach(events, id: \.objectID) { event in
                            Button(action: {
                                selectedEvent = event
                            }) {
                                EventCardPreview(event: event, cardSize: .bigCard)
                            }
                            .hapticFeedback(.light)
                        }
                    }
                }
            }
        }
        .background(theme.colors.background)
        .sheet(item: $selectedEvent) { event in
            EventFullSheetView(event: event)
                .presentationDetents([.large])
                .presentationBackgroundInteraction(.disabled)
                .presentationCornerRadius(theme.spacing.medium)
                .presentationDragIndicator(.hidden)
        }
    }
}

