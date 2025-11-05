//
//  SyncClock.swift
//  EventsApp
//
//  Created by Шоу on 10/31/25.
//

import Foundation

public struct SyncClock {
    public var now: () -> Date = { Date() }
    public init() {}
    public static let live = SyncClock()
}
