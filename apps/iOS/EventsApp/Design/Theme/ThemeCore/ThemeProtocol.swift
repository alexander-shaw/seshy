//
//  ThemeProtocol.swift
//  EventsApp
//
//  Created by Шоу on 10/14/25.
//

import SwiftUI

public protocol ThemeProtocol {
    var colors: Colors { get }
    var typography: Typography { get }
    var spacing: Spacing { get }
    var sizes: Sizes { get }
}
