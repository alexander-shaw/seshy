//
//  GenderCategory.swift
//  EventsApp
//
//  Created by Шоу on 10/25/25.
//

import Foundation

public enum GenderCategory: Int16, CaseIterable, Codable {
    case unknown = -1
    case male = 0
    case female = 1
    case nonbinary = 2
    case other = 3
}
