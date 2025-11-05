//
//  SyncMetrics.swift
//  EventsApp
//
//  Created by Шоу on 10/31/25.
//

import Foundation

public protocol SyncMetrics {
    func markCycleStart(trigger: String)
    func markCycleSuccess()
    func markCycleFailure(_ error: Error)
}

public final class LogSyncMetrics: SyncMetrics {
    public init() {}
    public func markCycleStart(trigger: String) { print("[Sync] cycle start (\(trigger))") }
    public func markCycleSuccess() { print("[Sync] cycle success") }
    public func markCycleFailure(_ error: Error) { print("[Sync] cycle failure: \(error)") }
}
