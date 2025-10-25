//
//  SyncStatus.swift
//  EventsApp
//
//  Created by Шоу on 10/25/25.
//

import Foundation

public enum SyncStatus: Int16, CaseIterable {
    case pending = 0
    case synced = 1
    case failed = 2
    case conflict = 3
}
