//
//  VibeCategory.swift
//  EventsApp
//
//  Created by Шоу on 10/25/25.
//

import Foundation

public enum VibeCategory: Int16 {
    case custom = 0  // User-created; do not use for ML.

    case energy = 1  // High energy, chill, dancer, always laughing, chaotic fun, etc.
    case locale = 2  // House parties, rooftop, basement, etc.
    case hobbies = 3  // House music, cooking, surfing, philosophy, travel, etc.
    case music = 4  // EDM, jazz, indie rock, classic rock, lo-fi, classical, etc.
    case cultural = 5  // Nostalgia binger, bookworm, reality TV addict, gamer, etc.

    case degree = 6
    case classStanding = 7
}
