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
    @Binding var newEventPath: NavigationPath
    @Binding var notificationsPath: NavigationPath
    @Binding var profilePath: NavigationPath

    @State private var bottomBarHeight: CGFloat = 44  // Fallback height.

    var body: some View {
        ZStack {
            // Main content views (excluding newEventTab which will be fullscreen).
            Group {
                if tabManager.currentTab == .discoverTab {
                    NavigationStack(path: $discoverPath) {
                        DiscoverListView(bottomBarHeight: $bottomBarHeight)
                    }
                } else if tabManager.currentTab == .calendarTab {
                    NavigationStack(path: $calendarPath) {
                        CalendarView(bottomBarHeight: $bottomBarHeight)
                    }
                } else if tabManager.currentTab == .notificationsTab {
                    NavigationStack(path: $notificationsPath) {
                        NotificationsView(bottomBarHeight: $bottomBarHeight)
                    }
                } else if tabManager.currentTab == .profileTab {
                    NavigationStack(path: $profilePath) {
                        ProfileView(bottomBarHeight: $bottomBarHeight)
                    }
                }
            }

            // Bottom bar anchored to bottom (only show if not on newEventTab).
            if tabManager.currentTab != .newEventTab {
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
            
            // Fullscreen newEventTab (on top of everything).
            if tabManager.currentTab == .newEventTab {
                NavigationStack(path: $newEventPath) {
                    NewEventView(tabManager: tabManager)
                }
                .transition(.opacity)
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}
