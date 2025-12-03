//
//  CircularProgressView.swift
//  EventsApp
//
//  Created by Шоу on 1/25/25.
//

import SwiftUI

struct CircularProgressView: View {
    @Environment(\.theme) private var theme
    @State private var shakeOffset: CGFloat = 0
    
    let current: Int
    let limit: Int
    
    private var progress: Double {
        min(Double(current) / Double(limit), 1.0)
    }
    
    private var progressColor: Color {
        if progress >= 1.0 {
            return .red
        } else if progress >= 0.95 {
            return .yellow
        } else {
            return .blue
        }
    }
    
    private var isOverLimit: Bool {
        current > limit
    }
    
    private var size: CGFloat {
        44
    }
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(theme.colors.surface.opacity(0.3), lineWidth: 3)
            
            // Progress circle
            Circle()
                .trim(from: 0, to: progress)
                .stroke(progressColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: progress)
        }
        .frame(width: size, height: size)
        .offset(x: shakeOffset)
        .onChange(of: isOverLimit) { _, newValue in
            if newValue {
                startShaking()
            } else {
                stopShaking()
            }
        }
        .onAppear {
            if isOverLimit {
                startShaking()
            }
        }
    }
    
    private func startShaking() {
        withAnimation(.easeInOut(duration: 0.1).repeatForever(autoreverses: true)) {
            shakeOffset = 2
        }
    }
    
    private func stopShaking() {
        withAnimation(.easeInOut(duration: 0.2)) {
            shakeOffset = 0
        }
    }
}


