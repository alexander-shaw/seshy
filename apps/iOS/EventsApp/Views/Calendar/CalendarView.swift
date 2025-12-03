//
//  CalendarView.swift
//  EventsApp
//
//  Created by Шоу on 10/25/25.
//

import SwiftUI
import CoreData

enum CalendarFlow: Identifiable {
    case openEvent(event: EventItem)
    case openQRCode

    var id: String {
        switch self {
            case .openEvent(let event):
                return event.objectID.uriRepresentation().absoluteString
            case .openQRCode:
                return "openQRCode"
        }
    }
}

struct CalendarView: View {
    @Binding var bottomBarHeight: CGFloat
    @Environment(\.theme) private var theme

    @State private var selectedEvent: CalendarFlow?
    @State private var events: [EventItem] = []
    
    private let repository: EventItemRepository = CoreEventItemRepository()

    // Separate events with and without startTime.
    private var eventsWithDates: [EventItem] {
        events.filter { $0.startTime != nil }
    }
    
    private var eventsWithoutDates: [EventItem] {
        events.filter { $0.startTime == nil }
    }
    
    // Group events by date (using startTime).
    private var eventsByDate: [Date: [EventItem]] {
        let grouped = Dictionary(grouping: eventsWithDates) { event in
            // Group by calendar day (ignoring time).
            Calendar.current.startOfDay(for: event.startTime!)
        }
        
        // Sort events within each date group: all-day events first, then by startTime.
        return grouped.mapValues { events in
            events.sorted { event1, event2 in
                // All-day events come first
                if event1.isAllDay != event2.isAllDay {
                    return event1.isAllDay
                }
                // Then sort by startTime
                return (event1.startTime ?? Date.distantPast) < (event2.startTime ?? Date.distantPast)
            }
        }
    }
    
    // Sorted dates for display.
    private var sortedDates: [Date] {
        eventsByDate.keys.sorted()
    }

    var body: some View {
        VStack(spacing: 0) {
            TitleView(
                titleText: TabType.calendarTab.rawValue,
                trailing: {
                    IconButton(icon: "ticket.fill") {
                        selectedEvent = .openQRCode
                    }
                }
            )

            // List of events grouped by date.
            if events.isEmpty {
                VStack {
                    Spacer()
                }
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: theme.spacing.medium) {
                        Text("Joined")
                            .headlineStyle()
                            .padding(.horizontal, theme.spacing.medium)

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
                        }

                        Text("Watching")
                            .headlineStyle()
                            .padding(.horizontal, theme.spacing.medium)

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
                        }

                        Text("Hosting")
                            .headlineStyle()
                            .padding(.horizontal, theme.spacing.medium)

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
                        }

                        // TODO: Show all joined events.  If attendance is not confirmed, offer refund option.
                        Text("Past")
                            .headlineStyle()
                            .padding(.horizontal, theme.spacing.medium)

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
                        }
                    }
                    .padding(.vertical, theme.spacing.medium)
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
            switch flow {
                case .openEvent(let event):
                    EventFullSheetView(event: event)
                        .presentationDetents([.large])
                        .presentationBackgroundInteraction(.disabled)
                        .presentationCornerRadius(theme.spacing.medium)
                        .presentationDragIndicator(.hidden)
                case .openQRCode:
                    QRCodeSheetView()
                        .presentationDetents([.large])
                        .presentationBackgroundInteraction(.disabled)
                        .presentationCornerRadius(theme.spacing.medium)
                        .presentationDragIndicator(.hidden)
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
    let events: [EventItem]
    let onEventTap: (EventItem) -> Void
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.small) {
            // Date Header (isolated to observe time updates separately):
            DateHeaderView(date: date)
                .padding(.horizontal, theme.spacing.medium)
                .padding(.bottom, theme.spacing.medium / 2)

            // Events (isolated from time updates):
            ForEach(events, id: \.objectID) { event in
                Button(action: {
                    onEventTap(event)
                }) {
                    CompactPreview(event: event)
                        .equatable()  // Prevents re-renders when event hasn't changed.
                }
                .hapticFeedback(.light)
            }
        }
    }
}

// Separate view for date header that can observe TimeViewModel without affecting children
private struct DateHeaderView: View {
    let date: Date
    @ObservedObject private var timeViewModel = TimeViewModel.shared
    @Environment(\.theme) private var theme
    
    private var formattedDate: String {
        let calendar = Calendar.autoupdatingCurrent
        let locale = Locale.autoupdatingCurrent
        return EventDateTimeFormatter.calendarHeader(for: date, now: timeViewModel.currentDateTime, calendar: calendar, locale: locale)
    }
    
    var body: some View {
        Text(formattedDate)
            .fontWeight(.bold)
            .bodyTextStyle()
    }
}
