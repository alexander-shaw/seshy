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
            TitleView(titleText: "Explore")

            // TODO: Date Picker Button.
            // Tap: Cycles through a short list: 2d -> 2w -> 1m -> 6m -> All.
            // Long-Press: Opens the native date picker, where user can select a date.
            // Haptic: Light on tap; medium on long-press.
            
            // List of events.
            if events.isEmpty {
                VStack {
                    Spacer()
                    AnimatedRingView()
                        .padding(.bottom, theme.spacing.large)
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
        .refreshable {
            // Pull to refresh.
            await fetchEventsAsync()
        }
        .sheet(item: $selectedEvent) { flow in
            if case .openEvent(let event) = flow {
                EventFullSheetView(event: event)
            }
        }
        .onAppear {
            fetchEvents()
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)) { _ in
            // Refresh when Core Data changes occur (after creating events or uploading media).
            fetchEvents()
        }
    }

    private func fetchEvents() {
        Task { @MainActor in
            await fetchEventsAsync()
        }
    }
    
    @MainActor
    private func fetchEventsAsync() async {
        do {
            print("Fetching published events.")
            let fetchedEvents = try await repository.getPublishedEvents()
            print("Fetched \(fetchedEvents.count) events.")

            // Log media info for each event.
            for event in fetchedEvents {
                if let mediaSet = event.media {
                    print("Event \(event.name) has \(mediaSet.count) media items.")
                    for media in mediaSet {
                        // Check if file exists using MediaURLResolver logic.
                        let filePath: String
                        if media.url.hasPrefix("file://") {
                            if let url = URL(string: media.url) {
                                filePath = url.path
                            } else {
                                filePath = String(media.url.dropFirst(7))
                            }
                        } else {
                            filePath = media.url
                        }
                        let exists = FileManager.default.fileExists(atPath: filePath)
                        let expectedPath = MediaStorageHelper.getMediaFileURL(mediaID: media.id, isVideo: media.isVideo).path
                        let expectedExists = FileManager.default.fileExists(atPath: expectedPath)
                        print("Media ID: \(media.id)")
                        print("URL: '\(media.url)'")
                        print("File exists (from URL):  \(exists) at \(filePath)")
                        print("Expected path (by ID):  \(expectedPath)")
                        print("File exists (by ID):  \(expectedExists)")
                    }
                } else {
                    print("Event \(event.name) has NO media.")
                }
            }
            
            self.events = fetchedEvents
        } catch {
            print("Failed to fetch events:  \(error)")
        }
    }
}
