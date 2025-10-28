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
    @State private var events: [UserEvent] = []

    // Map state - will be loaded from UserSettings
    @State private var centerCoordinate = CLLocationCoordinate2D(
        latitude: 46.7319,  // Washington State University default
        longitude: -117.1542
    )
    @State private var zoomLevel: Double = 15.0
    
    private let repository: UserEventRepository = CoreDataUserEventRepository()

    var body: some View {
        VStack(spacing: 0) {
            TitleView(titleText: "Discover", trailing: {
                IconButton(icon: "plus") {
                    discoverMapFlow = .openNewEvent
                }
            })

            // TODO: Date Picker Button.
            // Tap: Cycles through a short list: 2d -> 2w -> 1m -> 6m -> All.
            // Long-Press: Opens the native date picker, where user can select a date.
            // Haptic: Light on tap; medium on long-press.

            // Dark-styled Mapbox map with bottom padding for the bar.
            MapboxMapView(
                centerCoordinate: $centerCoordinate,
                zoomLevel: $zoomLevel,
                events: events,
                styleURI: .dark
            )
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
        // TODO: Integrate with UserSettingsViewModel
        // Keeping defaults for now.
    }
    
    private func fetchEvents() {
        Task { @MainActor in
            do {
                let fetchedEvents = try await repository.getPublishedEvents()
                self.events = fetchedEvents
                
                // Debug: Print events and their locations
                print("✅ Fetched \(fetchedEvents.count) events")
                for (index, event) in fetchedEvents.enumerated() {
                    let name = event.name
                    print("Event \(index): name=\(name ?? "nil"), id=\(event.id)")
                    print("  scheduleStatusRaw=\(event.scheduleStatusRaw)")
                    print("  visibilityRaw=\(event.visibilityRaw)")
                    
                    if let place = event.location {
                        print("  Location: name=\(place.name ?? "nil"), lat=\(place.latitude), lon=\(place.longitude)")
                    } else {
                        print("  ⚠️ No location")
                    }
                }
            } catch {
                print("Failed to fetch events: \(error)")
            }
        }
    }
}
