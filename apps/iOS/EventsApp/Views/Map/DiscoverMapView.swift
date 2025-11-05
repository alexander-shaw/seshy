//
//  DiscoverView.swift
//  EventsApp
//
//  Created by Шоу on 10/1/25.
//

import SwiftUI
import CoreLocation
import MapboxMaps
import CoreData

enum DiscoverMapFlow: Identifiable {
    case openNewEvent
    
    var id: String {
        switch self {
            case .openNewEvent: return "openNewEvent"
        }
    }
}

struct DiscoverMapView: View {
    @Binding var bottomBarHeight: CGFloat
    @Environment(\.theme) private var theme
    @Environment(\.managedObjectContext) private var viewContext

    @State private var discoverMapFlow: DiscoverMapFlow?
    @State private var events: [EventItem] = []

    private let repository: EventItemRepository = CoreEventItemRepository()

    var body: some View {
        VStack(spacing: 0) {
            TitleView(titleText: "Map")

            // Dark-styled Mapbox map with hexagons for events.
            UIKitDiscoverMapView(events: events, style: .dark)
                .padding(.bottom, bottomBarHeight)
        }
        .background(theme.colors.background)
        .fullScreenCover(item: $discoverMapFlow) { flow in
            switch flow {
                case .openNewEvent:
                    NewEventView()
            }
        }
        .onAppear {
            loadMapPreferences()
            fetchEvents()
        }
        .onChange(of: discoverMapFlow) { _, _ in
            if discoverMapFlow == nil {
                // Refresh events when returning from NewEventView
                fetchEvents()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)) { _ in
            fetchEvents()
        }
    }

    private func loadMapPreferences() {
        // TODO: Integrate with UserSettingsViewModel.
        // Keeping defaults for now.
    }
    
    private func fetchEvents() {
        Task { @MainActor in
            do {
                let fetchedEvents = try await repository.getPublishedEvents()
                self.events = fetchedEvents
                
                print("Fetched \(fetchedEvents.count) events.")
                for (idx, event) in fetchedEvents.enumerated() {
                    if let place = event.location {
                        print("  Event \(idx): \(event.name) at (\(place.latitude), \(place.longitude)) with color: \(event.brandColor)")
                    } else {
                        print("  Event \(idx): \(event.name) - no location")
                    }
                }
            } catch {
                print("Failed to fetch events:  \(error)")
            }
        }
    }
}
