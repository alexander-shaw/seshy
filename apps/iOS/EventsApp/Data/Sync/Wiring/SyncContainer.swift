//
//  SyncContainer.swift
//  EventsApp
//
//  Created by Шоу on 10/31/25.
//

import Foundation

public struct SyncContainer {
    public let engine: SyncEngine
    
    public init(api: APIClient, repos: Repos) {
        let policy = SyncPolicy()
        let scheduler = SyncScheduler()
        let metrics = LogSyncMetrics()
        let pull = PullUserDataTask(api: api, repos: repos, policy: policy)
        let push = PushPendingEditsTask(api: api, repos: repos, policy: policy)
        let process = ProcessServerEventsTask()

        self.engine = DefaultSyncEngine(scheduler: scheduler,
                                        pullTask: pull,
                                        pushTask: push,
                                        processEventsTask: process,
                                        metrics: metrics)
    }
}
