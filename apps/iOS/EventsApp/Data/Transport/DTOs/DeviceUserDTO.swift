//
//  DeviceUserDTO.swift
//  EventsApp
//
//  Created by Шоу on 10/14/25.
//

import Foundation

// Transport/Domain shape.
// Safe to cross actors and send to cloud.
public struct DeviceUserDTO: Codable, Sendable, Equatable {
    public let id: UUID
    public let username: String?
    public let updatedAt: Date
    public let schemaVersion: Int
}
