//
//  SplashView.swift
//  EventsApp
//
//  Created by Шоу on 10/11/25.
//

import SwiftUI

struct SplashView: View {
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                AnimatedRingView()
                Spacer()
            }
            Spacer()
        }
        .ignoresSafeArea()
        .background(theme.colors.background)
        .statusBarHidden(true)
    }
}
