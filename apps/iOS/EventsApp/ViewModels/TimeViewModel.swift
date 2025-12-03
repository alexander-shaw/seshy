//
//  TimeViewModel.swift
//  EventsApp
//
//  Created by Шоу on 11/8/25.
//

import SwiftUI
import Combine

class TimeViewModel: ObservableObject {
    
    static let shared = TimeViewModel()  // Singleton instance.

    @Published var currentDateTime: Date = Date()

    private init() {
        startUpdatingTime()
    }

    private func startUpdatingTime() {
        let nextSecond = Calendar.current.date(byAdding: .second, value: 1, to: Date())!
        let timeInterval = nextSecond.timeIntervalSinceNow

        DispatchQueue.global().asyncAfter(deadline: .now() + timeInterval) { [weak self] in
            DispatchQueue.main.async {
                self?.currentDateTime = Date()
                self?.startUpdatingTime()  // Schedule next update.
            }
        }
    }
}
