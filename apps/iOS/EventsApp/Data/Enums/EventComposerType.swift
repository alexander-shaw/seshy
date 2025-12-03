//
//  EventComposerType.swift
//  EventsApp
//
//  Created by Шоу on 11/25/25.
//

enum EventComposerType: String, Identifiable {
    case time
    case location
    case details
    case capacity
    case visibility
    case vibes
    case theme
    case tickets
    case team

    var id: String { rawValue }
}
