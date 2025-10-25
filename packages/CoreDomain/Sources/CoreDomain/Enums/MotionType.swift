//
//  MotionType.swift
//  EventsApp
//
//  Created by Шоу on 10/25/25.
//

import Foundation

// Lightweight to avoid coupling to CoreMotion/CoreData.
public enum MotionType: Int16 {
    case unknown = 0
    case stationary = 1
    case walking = 2
    case running = 3
    case cycling = 4
    case driving = 5
    case flying = 6
    case transition = 7
}
