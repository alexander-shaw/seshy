//
//  SplashView.swift
//  EventsApp
//
//  Created by Шоу on 10/11/25.
//

import SwiftUI
import Combine

struct SplashView: View {
    @Environment(\.theme) private var theme
    @EnvironmentObject private var userSession: UserSessionViewModel
    @StateObject private var viewModel = SplashViewModel()
    
    var body: some View {
        VStack {
            Spacer()

            AnimatedRingView()

            Spacer()
        }
        .task {
            await viewModel.performStartupSequence(using: userSession)
        }
        .ignoresSafeArea()
        .frame(maxWidth: .infinity)
        .background(theme.colors.background)
        .statusBarHidden(true)
    }
}
