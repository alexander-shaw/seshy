//
//  Members.swift
//  EventsApp
//
//  Created by Шоу on 10/25/25.
//

import Foundation

// TODO: Migrate to MemberRole entity.
public enum MemberRole: Int16 {
    case host = 0
    case staff = 1
    case guest = 2
}

public enum MemberStatus: Int16 {
    case active = 0
    case pending = 1
    case removed = 2
}
