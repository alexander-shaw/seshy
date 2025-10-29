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
import CoreDomain

enum DiscoverListFlow: Identifiable {
    case openNewEvent

    var id: String {
        switch self {
            case .openNewEvent: return "openNewEvent"
        }
    }
}

struct DiscoverListView: View {
    @Binding var bottomBarHeight: CGFloat
    @Environment(\.theme) private var theme

    @State private var discoverMapFlow: DiscoverListFlow?
    @State private var events: [UserEvent] = []
    
    private let repository: UserEventRepository = CoreDataUserEventRepository()

    var body: some View {
        VStack(spacing: 0) {
            TitleView(titleText: "Events")

            // TODO: Date Picker Button.
            // Tap: Cycles through a short list: 2d -> 2w -> 1m -> 6m -> All.
            // Long-Press: Opens the native date picker, where user can select a date.
            // Haptic: Light on tap; medium on long-press.
            
            // List of events.
            if events.isEmpty {
                VStack {
                    Spacer()

                    Text("No events found.")
                        .captionTextStyle()
                        .padding(.horizontal, theme.spacing.medium)

                    Spacer()
                }
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 12) {
                        ForEach(events, id: \.objectID) { event in
                            EventListRow(event: event)
                        }
                    }
                    .padding(.top, theme.spacing.small)
                    .padding(.horizontal, theme.spacing.medium)
                    .padding(.bottom, bottomBarHeight)
                }
            }
        }
        .background(theme.colors.background)
        .fullScreenCover(item: $discoverMapFlow) { flow in
            switch flow {
                case .openNewEvent:
                    NewEventView()
            }
        }
        .onAppear {
            fetchEvents()
        }
    }

    private func fetchEvents() {
        Task { @MainActor in
            do {
                let fetchedEvents = try await repository.getPublishedEvents()
                self.events = fetchedEvents
            } catch {
                print("Failed to fetch events in list view:  \(error)")
            }
        }
    }
}
