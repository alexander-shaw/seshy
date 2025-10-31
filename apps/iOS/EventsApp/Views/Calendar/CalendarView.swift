//
//  CalendarView.swift
//  EventsApp
//
//  Created by Шоу on 10/25/25.
//

// TODO: Filter events by a status attribute: watching, joined, requested, etc.

import SwiftUI
import CoreData
import CoreDomain

enum CalendarFlow: Identifiable {
    case openEvent(event: UserEvent)

    var id: String {
        switch self {
            case .openEvent(let event):
                return event.objectID.uriRepresentation().absoluteString
        }
    }
}

struct CalendarView: View {
    @Binding var bottomBarHeight: CGFloat
    @Environment(\.theme) private var theme

    @State private var selectedEvent: CalendarFlow?
    @State private var events: [UserEvent] = []
    
    private let repository: UserEventRepository = CoreDataUserEventRepository()
    
    // Separate events with and without startTime.
    private var eventsWithDates: [UserEvent] {
        events.filter { $0.startTime != nil }
    }
    
    private var eventsWithoutDates: [UserEvent] {
        events.filter { $0.startTime == nil }
    }
    
    // Group events by date (using startTime).
    private var eventsByDate: [Date: [UserEvent]] {
        let grouped = Dictionary(grouping: eventsWithDates) { event in
            // Group by calendar day (ignoring time).
            Calendar.current.startOfDay(for: event.startTime!)
        }
        
        // Sort events within each date group by startTime.
        return grouped.mapValues { events in
            events.sorted { event1, event2 in
                (event1.startTime ?? Date.distantPast) < (event2.startTime ?? Date.distantPast)
            }
        }
    }
    
    // Sorted dates for display.
    private var sortedDates: [Date] {
        eventsByDate.keys.sorted()
    }

    var body: some View {
        VStack(spacing: 0) {
            TitleView(titleText: "Calendar")

            // List of events grouped by date.
            if events.isEmpty {
                VStack {
                    Spacer()
                    AnimatedRingView()
                        .padding(.bottom, theme.spacing.large)
                    Spacer()
                }
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: theme.spacing.medium) {
                        // Events grouped by date.
                        ForEach(sortedDates, id: \.self) { date in
                            DateSection(
                                date: date,
                                events: eventsByDate[date] ?? [],
                                onEventTap: { event in
                                    selectedEvent = .openEvent(event: event)
                                }
                            )
                        }
                    }
                    .padding(theme.spacing.medium)
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
            // Refresh when Core Data changes occur.
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
            print("Fetching published events for calendar.")
            let fetchedEvents = try await repository.getPublishedEvents()
            print("Fetched \(fetchedEvents.count) published events for calendar.")
            
            self.events = fetchedEvents
        } catch {
            print("Failed to fetch events:  \(error)")
        }
    }
}

private struct DateSection: View {
    let date: Date
    let events: [UserEvent]
    let onEventTap: (UserEvent) -> Void
    
    @Environment(\.theme) private var theme

    // Formatted date.
    private var formattedDate: String {
        let calendar = Calendar.autoupdatingCurrent
        let locale = Locale.autoupdatingCurrent
        let timeZone = TimeZone.autoupdatingCurrent

        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        let startOfTarget = calendar.startOfDay(for: date)

        let currentYear = calendar.component(.year, from: now)
        let targetYear = calendar.component(.year, from: date)
        let daysUntil = calendar.dateComponents([.day], from: startOfToday, to: startOfTarget).day ?? 0

        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = timeZone

        // If next year, then "October 31, 2026".
        if targetYear > currentYear {
            formatter.setLocalizedDateFormatFromTemplate("MMMM d, yyyy")
            return formatter.string(from: date)
        }

        // If < 7 days from today (future), show weekday like "Friday".
        if daysUntil >= 0 && daysUntil < 7 {
            formatter.setLocalizedDateFormatFromTemplate("EEEE")
            return formatter.string(from: date)
        }

        // Otherwise (7+ days this year, or any past date this year), show "November 10".
        formatter.setLocalizedDateFormatFromTemplate("MMMM d")
        return formatter.string(from: date)
    }

    
    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.small) {
            // Date header.
            Text(formattedDate)
                .headlineStyle()
                .padding(.bottom, theme.spacing.small / 2)
            
            // Events for this date.
            VStack(spacing: theme.spacing.small) {
                ForEach(events, id: \.objectID) { event in
                    Button(action: {
                        onEventTap(event)
                    }) {
                        CalendarEventRow(event: event)
                    }
                }
            }
        }
    }
}

// MARK: - COMPACT PREVIEW:

private struct CalendarEventRow: View {
    let event: UserEvent
    
    @Environment(\.theme) private var theme
    
    // Format start time
    private var formattedTime: String {
        guard let startTime = event.startTime else {
            return "?"
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: startTime)
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: theme.spacing.small) {
            // Time:
            Text(formattedTime)
                .captionTitleStyle()
                .frame(minWidth: 60, alignment: .leading)

            Divider()
                .foregroundStyle(theme.colors.surface)

            // Event name:
            Text(event.name)
                .bodyTextStyle()
            
            Spacer(minLength: 0)

            Circle()
                .fill(Color(hex: event.brandColor) ?? Color.clear)  // TODO: Status color or icon: watching, joined, requested, etc.
                .frame(width: theme.spacing.small / 2, height: theme.spacing.small / 2)
        }
        .padding(.vertical, theme.spacing.small)
        .padding(.horizontal, theme.spacing.medium)
        .background(theme.colors.surface)
        .cornerRadius(12)
    }
}
