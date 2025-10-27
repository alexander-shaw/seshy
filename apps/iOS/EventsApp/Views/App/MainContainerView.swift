//
//  MainContainerView.swift
//  EventsApp
//
//  Created by Шоу on 10/1/25.
//

import SwiftUI
import Combine

struct MainContainerView: View {
    @StateObject var tabManager: TabManager

    @Binding var discoverPath: NavigationPath
    @Binding var calendarPath: NavigationPath
    @Binding var profilePath: NavigationPath

    @State private var bottomBarHeight: CGFloat = 44  // Fallback height.

    var body: some View {
        ZStack {
            // Main content views.
            Group {
                if tabManager.currentTab == .discoverTab {
                    NavigationStack(path: $discoverPath) {
                        DiscoverView(bottomBarHeight: $bottomBarHeight)
                    }
                } else if tabManager.currentTab == .calendarTab {
                    NavigationStack(path: $calendarPath) {
                        CalendarView(bottomBarHeight: $bottomBarHeight)
                    }
                } else if tabManager.currentTab == .profileTab {
                    NavigationStack(path: $profilePath) {
                        ProfileView(bottomBarHeight: $bottomBarHeight)
                    }
                }
            }

            // Bottom bar anchored to bottom.
            VStack {
                Spacer()
                BottomBarView(tabManager: tabManager)
                    .background(
                        GeometryReader { geo in
                            Color.clear
                                .onAppear {
                                    bottomBarHeight = geo.size.height
                                }
                                .onChange(of: geo.size.height) {
                                    bottomBarHeight = geo.size.height
                                }
                        }
                    )
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}
