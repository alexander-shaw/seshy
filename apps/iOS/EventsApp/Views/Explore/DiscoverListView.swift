//
//  DiscoverListView.swift
//  EventsApp
//
//  Created by Шоу on 10/25/25.
//

// Personalized stacks of horizontal carousels, where each row is a story.

// Tier 1 (always shown first): Your Invites / Near You / Tonight / This Weekend
// Tier 2 (relevance): Your Vibes / You Might Like (based on attendance & ratings) / Friends Are Interested / Most Watched / Trending
// Tier 3 (curated): Late-Night Picks / Rooftop / After Parties / Invite-Only Clubs / Last Spots Left / Promoted
// Tier 4 (theme-based): Chill & Low Key / High Energy / Greek Life Highlights / Open to All / Music-Focused
// Tier 5 (dynamic): Recently Created / Hosts You Follow

import SwiftUI
import CoreData

enum DiscoverListFlow: Identifiable {
    case openEvent(event: EventItem)
    case expandSection(section: DiscoverSection)

    var id: String {
        switch self {
        case .openEvent(let event):
            return event.objectID.uriRepresentation().absoluteString
        case .expandSection(let section):
            return section.id
        }
    }
}

enum LocationSheetItem: Identifiable {
    case permission
    case manual
    
    var id: String {
        switch self {
            case .permission: return "permission"
            case .manual: return "manual"
        }
    }
}

struct DiscoverListView: View {
    @Binding var bottomBarHeight: CGFloat
    @Environment(\.theme) private var theme
    @EnvironmentObject private var userSession: UserSessionViewModel
    @ObservedObject private var locationViewModel = LocationViewModel.shared

    @State private var activeFlow: DiscoverListFlow?
    @State private var showLocationSheet: LocationSheetItem?
    
    // Store events for each section independently
    @State private var sectionEvents: [DiscoverSection: [EventItem]] = [:]

    private let repository: EventItemRepository = CoreEventItemRepository()

    var body: some View {
        VStack(spacing: 0) {
            TitleView(
                titleText: TabType.discoverTab.rawValue,
                trailing: {
                    if !locationViewModel.trackingPreferenceEnabled {
                        IconButton(icon: "map.fill") {
                            locationViewModel.startLocationFlow()
                            // Show sheet based on current step
                            switch locationViewModel.currentStep {
                                case .permission:
                                    showLocationSheet = .permission
                                case .manual:
                                    showLocationSheet = .manual
                            }
                        }
                    }
                }
            )

            // List of events.
            if sectionEvents.isEmpty {
                VStack {
                    Spacer()
                }
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: theme.spacing.large) {
                        ForEach(DiscoverSection.allCases) { section in
                            if let events = sectionEvents[section], !events.isEmpty {
                                EventCarouselSection(
                                    section: section,
                                    events: events,
                                    onEventTap: { event in
                                        activeFlow = .openEvent(event: event)
                                    },
                                    onExpandTap: events.count > 10 ? {
                                        activeFlow = .expandSection(section: section)
                                    } : nil
                                )
                            }
                        }
                    }
                    .padding(.vertical, theme.spacing.medium)
                    .padding(.bottom, bottomBarHeight)
                }
            }
        }
        .background(theme.colors.background)
        .refreshable {
            // Pull to refresh all sections.
            await fetchAllSectionsAsync()
        }
        .sheet(item: $activeFlow) { flow in
            switch flow {
                case .openEvent(let event):
                    EventFullSheetView(event: event)
                        .presentationDetents([.large])
                        .presentationBackgroundInteraction(.disabled)
                        .presentationCornerRadius(theme.spacing.medium)
                        .presentationDragIndicator(.hidden)
                case .expandSection(let section):
                    if let events = sectionEvents[section] {
                        ExpandedExploreView(
                            section: section,
                            events: events,
                            onEventTap: { event in
                                activeFlow = .openEvent(event: event)
                            }
                        )
                        .presentationDetents([.large])
                        .presentationBackgroundInteraction(.disabled)
                        .presentationCornerRadius(theme.spacing.medium)
                        .presentationDragIndicator(.hidden)
                    }
            }
        }
        .sheet(item: $showLocationSheet) { item in
            switch item {
                case .permission:
                    LocationPermissionView(
                        onManualEntryRequested: {
                            showLocationSheet = .manual
                        }
                    )
                    .presentationDetents([.large])
                    .presentationBackgroundInteraction(.disabled)
                    .presentationCornerRadius(theme.spacing.medium)
                    .presentationDragIndicator(.hidden)
                case .manual:
                    LocationMapSheetView(onDismiss: {
                        showLocationSheet = nil
                    })
                        .presentationDetents([.large])
                        .presentationBackgroundInteraction(.disabled)
                        .presentationCornerRadius(theme.spacing.medium)
                        .presentationDragIndicator(.hidden)
            }
        }
        .onAppear {
            locationViewModel.updateUserSession(userSession)
            fetchAllSections()
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)) { _ in
            fetchAllSections()  // Refresh when Core Data changes occur (after creating events or uploading media).
        }
    }

    private func fetchAllSections() {
        Task { @MainActor in
            await fetchAllSectionsAsync()
        }
    }
    
    @MainActor
    private func fetchAllSectionsAsync() async {
        // Fetch events for each section independently
        // In production, these would be optimized fetch requests per section
        var newSectionEvents: [DiscoverSection: [EventItem]] = [:]
        
        await withTaskGroup(of: (DiscoverSection, [EventItem]?).self) { group in
            for section in DiscoverSection.allCases {
                group.addTask {
                    do {
                        let events = try await section.fetchEvents(repository: self.repository)
                        return (section, events)
                    } catch {
                        print("Failed to fetch events for section \(section.title): \(error)")
                        return (section, nil)
                    }
                }
            }
            
            for await (section, events) in group {
                if let events = events {
                    newSectionEvents[section] = events
                }
            }
        }
        
        self.sectionEvents = newSectionEvents
    }
}
