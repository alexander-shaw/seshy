//
//  DiscoverListView.swift
//  EventsApp
//
//  Created by Шоу on 10/25/25.
//

import SwiftUI
import CoreData
import CoreDomain

enum DiscoverListFlow: Identifiable {
    case openEvent(event: UserEvent)

    var id: String {
        switch self {
            case .openEvent(let event):
                return event.objectID.uriRepresentation().absoluteString
        }
    }
}

struct DiscoverListView: View {
    @Binding var bottomBarHeight: CGFloat
    @Environment(\.theme) private var theme

    @State private var selectedEvent: DiscoverListFlow?
    @State private var events: [UserEvent] = []
    
    private let repository: UserEventRepository = CoreDataUserEventRepository()

    var body: some View {
        VStack(spacing: 0) {
            TitleView(titleText: "Discover")

            // TODO: Date Picker Button.
            // Tap: Cycles through a short list: 2d -> 2w -> 1m -> 6m -> All.
            // Long-Press: Opens the native date picker, where user can select a date.
            // Haptic: Light on tap; medium on long-press.
            
            // List of events.
            if events.isEmpty {
                VStack {
                    Spacer()

                    Text("Requesting new events.")
                        .captionTextStyle()
                        .padding(.horizontal, theme.spacing.medium)

                    Spacer()
                }
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: theme.spacing.medium) {
                        ForEach(events, id: \.objectID) { event in
                            Button(action: {
                                selectedEvent = .openEvent(event: event)
                            }) {
                                EventPreview(event: event)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.bottom, bottomBarHeight)
                }
            }
        }
        .background(theme.colors.background)
        .sheet(item: $selectedEvent) { flow in
            if case .openEvent(let event) = flow {
                EventFullSheetView(event: event)
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
