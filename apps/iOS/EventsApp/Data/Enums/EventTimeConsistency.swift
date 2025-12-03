//
//  EventTimeConsistency.swift
//  EventsApp
//
//  Created by Шоу on 11/25/25.
//

import Foundation

public enum EventTimeMode: String, CaseIterable, Identifiable {
    case none
    case end
    case duration
    case allDay

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .none: return "None"
        case .end: return "End"
        case .duration: return "Duration"
        case .allDay: return "All-Day"
        }
    }
}

public struct EventTimeSnapshot: Equatable {
    public var start: Date?
    public var end: Date?
    public var durationMinutes: Int?
    public var isAllDay: Bool

    public init(start: Date?, end: Date?, durationMinutes: Int?, isAllDay: Bool) {
        self.start = start
        self.end = end
        self.durationMinutes = durationMinutes
        self.isAllDay = isAllDay
    }
}

public enum EventTimeConsistency {
    /// Normalizes the trio of start/end/duration based on the chosen mode.
    public static func normalized(
        snapshot: EventTimeSnapshot,
        mode: EventTimeMode,
        calendar: Calendar = .current
    ) -> EventTimeSnapshot {
        var start = snapshot.start
        var end = snapshot.end
        var duration = snapshot.durationMinutes
        var isAllDay = snapshot.isAllDay

        switch mode {
        case .none:
            isAllDay = false
            end = nil
            duration = nil
        case .allDay:
            isAllDay = true
            duration = nil
            if let startDate = start {
                start = calendar.startOfDay(for: startDate)
                end = calendar.date(byAdding: DateComponents(day: 1, second: -1), to: start ?? startDate)
            } else {
                end = nil
            }
        case .end:
            isAllDay = false
            if let startDate = start {
                if let endDate = end {
                    if endDate < startDate {
                        end = max(startDate, endDate)
                    }
                } else if let durationMinutes = duration {
                    end = calendar.date(byAdding: .minute, value: durationMinutes, to: startDate)
                }
            }
            duration = nil
        case .duration:
            isAllDay = false
            if let startDate = start {
                if duration == nil {
                    duration = defaultDurationMinutes
                }
                if let durationMinutes = duration {
                    end = calendar.date(byAdding: .minute, value: durationMinutes, to: startDate)
                }
            } else {
                end = nil
            }
        }

        if start == nil {
            end = nil
            duration = mode == .duration ? duration : nil
        }

        return EventTimeSnapshot(start: start, end: end, durationMinutes: duration, isAllDay: isAllDay)
    }

    /// Applies a duration increment (e.g., +3h quick action) and normalizes again.
    public static func applyingDuration(
        minutes: Int,
        to snapshot: EventTimeSnapshot,
        calendar: Calendar = .current
    ) -> EventTimeSnapshot {
        var updated = snapshot
        updated.durationMinutes = minutes
        updated.isAllDay = false
        updated = normalized(snapshot: updated, mode: .duration, calendar: calendar)
        return updated
    }

    public static let defaultDurationMinutes: Int = 120
}

