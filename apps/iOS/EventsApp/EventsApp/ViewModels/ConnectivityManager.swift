//
//  ConnectivityManager.swift
//  Invited
//
//  Created by Шоу on 7/11/25.
//

import Network
import Combine

final class ConnectivityManager: ObservableObject {
    static let shared = ConnectivityManager()

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

    func checkCloudConnection() {
        // Google Firebase.

        // Google Cloud PostgreSQL.

        return
    }
}
