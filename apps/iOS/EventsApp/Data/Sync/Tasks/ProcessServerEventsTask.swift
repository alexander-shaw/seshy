//
//  ProcessServerEventsTask.swift
//  EventsApp
//
//  Created by Шоу on 10/31/25.
//

import Foundation

// Optional hook: if backend emits a small list of server events (collapse/replace threads), process them here.
// Safe to keep empty for now.
public struct ProcessServerEventsTask {
    public init() {}
    public func run() async throws { /* no-op */ }
}
