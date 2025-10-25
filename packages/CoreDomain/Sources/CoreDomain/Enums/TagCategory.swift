//
//  TagCategory.swift
//  EventsApp
//
//  Created by Шоу on 10/25/25.
//

import Foundation

public enum TagCategory: Int16 {
    case custom = 0  // User-created.
    case vibe = 1  // High energy, chill, dancer, always laughing, chaotic fun, etc.
    case localePreference = 2  // House parties, rooftop, basement, etc.
    case hobbies = 3  // House music, cooking, surfing, philosophy, travel, etc.
    case musicTaste = 4  // EDM, jazz, indie rock, classic rock, lo-fi, classical, etc.
    case culturalTaste = 5  // Nostalgia binger, bookworm, reality TV addict, gamer, etc.

    case degreeMajor = 6
    case classStanding = 7
}

// TODO: Adjust and add other cases.  Convert from Int16 to String?
