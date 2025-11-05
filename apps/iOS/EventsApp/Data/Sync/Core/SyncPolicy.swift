//
//  SyncPolicy.swift
//  EventsApp
//
//  Created by Шоу on 10/31/25.
//

import Foundation

public enum ConflictRule { case serverWins, clientWins, lastWriteWins }

public struct SyncPolicy {
    public var publicProfile: ConflictRule = .serverWins
    public var settings: ConflictRule = .lastWriteWins
    public var notifications: ConflictRule = .serverWins
    public var devices: ConflictRule = .serverWins

    public init() {}
}
