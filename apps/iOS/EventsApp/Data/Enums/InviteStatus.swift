//
//  InviteStatus.swift
//  EventsApp
//
//  Created by Шоу on 10/25/25.
//

import Foundation

public enum InviteStatus: Int16 {
    case pending = 0
    case approved = 1
    case declined = 2
    case expired = 3
    case revoked = 4
}
