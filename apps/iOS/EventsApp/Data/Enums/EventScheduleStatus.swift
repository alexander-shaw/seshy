//
//  EventScheduleStatus.swift
//  EventsApp
//
//  Created by Шоу on 10/25/25.
//

import Foundation

public enum EventScheduleStatus: Int, CaseIterable, Identifiable {
    case draft = 0
    case scheduled = 1
    case archived = 2

    public var id: Int { rawValue }

    public var title: String {
        switch self {
        case .draft: return "Draft"
        case .scheduled: return "Scheduled"
        case .archived: return "Archived"
        }
    }
}

// MARK: - Domain Mapping
extension EventScheduleStatus {
    var domainValue: EventStatus {
        switch self {
            case .draft:
                return .draft
            case .scheduled:
                return .upcoming
            case .archived:
                return .ended
        }
    }

    init(domainValue: EventStatus) {
        switch domainValue {
            case .draft:
                self = .draft
            case .upcoming, .live:
                self = .scheduled
            case .ended, .cancelled:
                self = .archived
        }
    }
}

