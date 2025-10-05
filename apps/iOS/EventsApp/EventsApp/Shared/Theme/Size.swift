//
//  Size.swift
//  EventsApp
//
//  Created by Шоу on 10/1/25.
//

import SwiftUI

extension Theme {
    struct Size {
        static let screenWidth: CGFloat = UIScreen.main.bounds.width
        static let screenHeight: CGFloat = UIScreen.main.bounds.height
        
        static let countryCodeWidth: CGFloat = screenWidth * 0.20
        static let numberFieldWidth: CGFloat = 48
        static let numberFieldHeight: CGFloat = 60
        
        static let iconButton: CGFloat = 48  // At least 44.
    }
}
