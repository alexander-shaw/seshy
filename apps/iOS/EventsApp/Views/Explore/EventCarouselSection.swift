//
//  EventCarouselSection.swift
//  EventsApp
//
//  Created by Шоу on 10/25/25.
//

import SwiftUI

// Reusable carousel section component for discover view
// Shows a horizontal scrollable list of events with a header
struct EventCarouselSection: View {
    let section: DiscoverSection
    let events: [EventItem]
    let onEventTap: (EventItem) -> Void
    let onExpandTap: (() -> Void)?
    
    @Environment(\.theme) private var theme
    
    private var previewEvents: [EventItem] {
        Array(events.prefix(section.previewLimit))
    }
    
    private var shouldShowExpandButton: Bool {
        events.count > 10 && onExpandTap != nil
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.medium) {
            HStack(alignment: .bottom, spacing: 0) {
                Text(section.title)
                    .headlineStyle()
                    .onTapGesture {
                        if shouldShowExpandButton {
                            onExpandTap?()
                        }
                    }

                Spacer()
            }
            .padding(.horizontal, theme.spacing.medium)
            
            if !previewEvents.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(alignment: .top, spacing: theme.spacing.medium * 3 / 4) {
                        ForEach(previewEvents, id: \.objectID) { event in
                            Button(action: {
                                onEventTap(event)
                            }) {
                                EventCardPreview(event: event, cardSize: .smallCard)
                            }
                            .buttonStyle(CollapseButtonStyle(pressedScale: 0.95))
                            .hapticFeedback(.light)
                        }
                    }
                    .padding(.horizontal, theme.spacing.medium)
                }
            }
        }
    }
}




