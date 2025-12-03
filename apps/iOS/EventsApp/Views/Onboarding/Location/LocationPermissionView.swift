//
//  LocationPermissionView.swift
//  EventsApp
//
//  Created by Шоу on 11/27/25.
//

import SwiftUI

struct LocationPermissionView: View {
    @Environment(\.theme) private var theme
    @ObservedObject private var locationViewModel = LocationViewModel.shared
    
    var onManualEntryRequested: () -> Void
    
    @State private var isRequestingPermission = false
    
    var body: some View {
        HStack {
            Spacer()

            VStack(alignment: .leading, spacing: theme.spacing.medium) {
                PrimaryButton(title: "Add location", isDisabled: isRequestingPermission) {
                    isRequestingPermission = true
                    locationViewModel.requestPermission()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.50) {
                        isRequestingPermission = false
                    }
                }

                PrimaryButton(title: "Enter manually instead", backgroundColor: AnyShapeStyle(Color.clear)) {
                    onManualEntryRequested()
                }
            }

            Spacer()
        }
    }
}
