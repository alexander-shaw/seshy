//
//  H3NodeDTO.swift
//  EventsApp
//
//  Created by Шоу on 10/14/25.
//

import Foundation

// Transport/Domain shape.
// Safe to cross actors and send to cloud.
public struct H3NodeDTO: Codable, Sendable, Equatable {
    public let id: UUID
    public let timestamp: Date
    public let horizontalAccuracy: Double?
    public let altitude: Double?
    public let verticalAccuracy: Double?
    public let speed: Double?
    public let speedAccuracy: Double?
    public let course: Double?
    public let courseAccuracy: Double?
    public let motionTypeRaw: Int16
    public let resolution: Int16
    public let h3Index: Int64
    public let updatedAt: Date
    public let schemaVersion: Int
}


