//
//  ConnectivityViewModel.swift
//  EventsApp
//
//  Created by Шоу on 10/1/25.
//

import Network
import Combine

final class ConnectivityViewModel: ObservableObject {
    static let shared = ConnectivityViewModel()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "ConnectivityMonitor")

    @Published private(set) var isConnectedToNetwork = true

    // MARK: - CHECK IF ONLINE:
    var isOnline: Bool {
        isConnectedToNetwork
    }

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnectedToNetwork = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }
}
