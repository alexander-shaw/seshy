//
//  SyncScheduler.swift
//  EventsApp
//
//  Created by Шоу on 10/31/25.
//

import Foundation

public final class SyncScheduler {
    public var onTick: (() async -> Void)?
    private var timer: Timer?
    private var interval: TimeInterval
    private var backoffMultiplier: Double = 1.0
    private let clock: SyncClock

    public init(interval: TimeInterval = 120, clock: SyncClock = .live) {
        self.interval = interval
        self.clock = clock
    }

    public func start() {
        stop()
        timer = Timer.scheduledTimer(withTimeInterval: interval * backoffMultiplier, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { await self.onTick?() }
        }
    }

    public func stop() {
        timer?.invalidate()
        timer = nil
        backoffMultiplier = 1.0
    }

    public func backoff() {
        // Cap backoff at 10x.
        backoffMultiplier = min(backoffMultiplier * 2.0, 10.0)
        start()
    }
}
