//
//  SyncEngine.swift
//  EventsApp
//
//  Created by Шоу on 10/31/25.
//

import Foundation

public protocol SyncEngine {
    func start()  // App active; good network.
    func stop()  // App background; logout.
    func kick(reason: String)  // Login; user edit; push received; app foreground.
}

// Default implementation that orchestrates phases and tasks.
public final class DefaultSyncEngine: SyncEngine {
    private let scheduler: SyncScheduler
    private let pullTask: PullUserDataTask
    private let pushTask: PushPendingEditsTask
    private let processEventsTask: ProcessServerEventsTask
    private let metrics: SyncMetrics
    private var isRunning = false
    private var publicProfileETag: String?
    private var settingsETag: String?
    private var loginETag: String?

    public init(scheduler: SyncScheduler,
                pullTask: PullUserDataTask,
                pushTask: PushPendingEditsTask,
                processEventsTask: ProcessServerEventsTask,
                metrics: SyncMetrics
    ) {
        self.scheduler = scheduler
        self.pullTask = pullTask
        self.pushTask = pushTask
        self.processEventsTask = processEventsTask
        self.metrics = metrics

        self.scheduler.onTick = { [weak self] in
            await self?.runCycle(trigger: "tick")
        }
    }

    public func start() {
        guard !isRunning else { return }
        isRunning = true
        scheduler.start()
        Task { await runCycle(trigger: "start") }
    }

    public func stop() {
        isRunning = false
        scheduler.stop()
    }

    public func kick(reason: String) {
        guard isRunning else { return }
        Task { await runCycle(trigger: reason) }
    }

    @MainActor
    private func runCycle(trigger: String) async {
        metrics.markCycleStart(trigger: trigger)
        do {
            // 1) Pull user data (ETag 304 means no work).
            let publicProfileETagResult = try await pullTask.pullPublicProfile(etag: publicProfileETag)
            if let newTag = publicProfileETagResult {
                publicProfileETag = newTag
            }
            
            let settingsETagResult = try await pullTask.pullSettings(etag: settingsETag)
            if let newTag = settingsETagResult {
                settingsETag = newTag
            }
            
            let loginETagResult = try await pullTask.pullLogin(etag: loginETag)
            if let newTag = loginETagResult {
                loginETag = newTag
            }

            // 2) Push local pending edits.
            try await pushTask.run()

            // 3) Process any server events (optional hook).
            try await processEventsTask.run()

            metrics.markCycleSuccess()
        } catch {
            metrics.markCycleFailure(error)
            scheduler.backoff()
        }
    }
}
