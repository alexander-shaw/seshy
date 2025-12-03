//
//  QRCodeSheetView.swift
//  EventsApp
//
//  Created by GPT-5.1 Codex on 11/28/25.
//

import SwiftUI
import Combine
import UIKit
import AVFoundation

enum QRSheetMode {
    case scan
    case access
}

struct QRCodeSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @EnvironmentObject private var userProfileViewModel: UserProfileViewModel

    @StateObject private var scanner = QRCodeScanner()

    @State private var mode: QRSheetMode = .access
    @State private var qrImage: UIImage?
    @State private var lastScanMessage: String?
    @State private var showCameraSettingsAlert = false
    @State private var previousBrightness: CGFloat = UIScreen.main.brightness

    private let qrGenerator = QRCodeGenerator()
    private let demoProfileID = UUID(uuidString: "11111111-1111-1111-1111-111111111111") ?? UUID()

    var body: some View {
        ZStack {
            theme.colors.background
                .ignoresSafeArea()

            VStack(spacing: theme.spacing.large) {
                header
                    .padding(.horizontal, theme.spacing.medium)

                segmentedControl
                    .padding(.horizontal, theme.spacing.medium)

                VStack(alignment: .leading, spacing: 4) {
                    Text(userProfileViewModel.displayName.isEmpty ? "" : userProfileViewModel.displayName)
                        .headlineStyle()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, theme.spacing.medium)

                content
                    .padding(.horizontal, theme.spacing.medium)

                Spacer(minLength: theme.spacing.medium)
            }
            .padding(.top, theme.spacing.large)
        }
        .onAppear {
            previousBrightness = UIScreen.main.brightness
            prepareQRCode()
            handleModeChange(mode)
            _ = userProfileViewModel  // Reference to avoid warnings until real data wiring returns.
            scanner.onPayload = { payload in
                // TODO: Trigger shared random color flash handshake between devices.
                lastScanMessage = "Captured id \(payload.id.uuidString.prefix(6))"
            }
        }
        .onChange(of: mode) { _, newValue in
            handleModeChange(newValue)
        }
        .onDisappear {
            cleanup()
        }
        .alert("Camera Permission Needed", isPresented: $showCameraSettingsAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Enable camera access in Settings to scan QR codes.")
        }
        .presentationDetents([.large])
        .presentationCornerRadius(32)
        .presentationBackground(.clear)
        .presentationDragIndicator(.hidden)
    }

    private var header: some View {
        HStack {
            IconButton(icon: "chevron.down") {
                dismiss()
            }

            Spacer()

            if mode == .scan {
                IconButton(icon: scanner.torchActive ? "flashlight.on.fill" : "flashlight.off.fill") {
                    toggleFlashlight()
                }
                .disabled(!scanner.torchAvailable)
            }
        }
    }

    private var segmentedControl: some View {
        HStack(spacing: 0) {
            segmentButton(title: "Scan", targetMode: .scan)
            segmentButton(title: "My Code", targetMode: .access)
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: theme.spacing.large)
                .fill(Color.white.opacity(0.08))
        )
    }

    private func segmentButton(title: String, targetMode: QRSheetMode) -> some View {
        Button {
            mode = targetMode
        } label: {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(mode == targetMode ? Color.black : theme.colors.offText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, theme.spacing.small)
                .background(
                    RoundedRectangle(cornerRadius: theme.spacing.large)
                        .fill(mode == targetMode ? Color.white : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var content: some View {
        switch mode {
            case .access:
                accessContent
            case .scan:
                scanContent
        }
    }

    private var accessContent: some View {
        VStack(spacing: theme.spacing.medium) {
            if let qrImage {
                Image(uiImage: qrImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .padding(theme.spacing.medium)
                    .background(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(Color.white)
                    )
            } else {
                ProgressView()
                    .progressViewStyle(.circular)
                    .frame(height: 280)
            }
        }
    }

    private var scanContent: some View {
        VStack(spacing: theme.spacing.medium) {
            if scanner.authorizationStatus == .authorized {
                ZStack {
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.2), lineWidth: 2)
                        .background(
                            RoundedRectangle(cornerRadius: 32, style: .continuous)
                                .fill(Color.black.opacity(0.4))
                        )

                    CameraPreviewView(scanner: scanner)
                        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                }
                .aspectRatio(1, contentMode: .fit)
            } else {
                VStack(spacing: theme.spacing.medium) {
                    Image(systemName: "camera.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 48, height: 48)
                        .foregroundStyle(.white)

                    Text("Camera access is required to scan codes.")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Button(action: openSettings) {
                        Text("Open Settings")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.black)
                            .padding(.horizontal, theme.spacing.large)
                            .padding(.vertical, theme.spacing.small)
                            .background(Color.white)
                            .clipShape(Capsule())
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 280)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .fill(Color.black.opacity(0.4))
                )
            }

            if let message = lastScanMessage {
                Text(message)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(theme.colors.offText)
            }
        }
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    private func prepareQRCode() {
        self.qrImage = qrGenerator.makeQRCodeImage(from: demoProfileID, dimension: 320)
        
        if qrImage == nil {
            print("QRCodeSheetView: Failed to generate QR code image")
        } else {
            print("QRCodeSheetView: Successfully generated QR code image")
        }
    }

    private func handleModeChange(_ newMode: QRSheetMode) {
        switch newMode {
        case .access:
            updateBrightness(forAccessMode: true)
            scanner.stop()
        case .scan:
            updateBrightness(forAccessMode: false)
            prepareScanner()
        }
    }

    private func updateBrightness(forAccessMode enabled: Bool) {
        if enabled {
            previousBrightness = UIScreen.main.brightness
            UIScreen.main.brightness = 1.0
        } else {
            UIScreen.main.brightness = previousBrightness
        }
    }

    private func prepareScanner() {
        switch scanner.authorizationStatus {
        case .authorized:
            scanner.start()
        case .notDetermined:
            scanner.requestPermission { granted in
                if granted {
                    scanner.start()
                } else {
                    showCameraSettingsAlert = true
                }
            }
        default:
            showCameraSettingsAlert = true
        }
    }

    private func toggleFlashlight() {
        guard scanner.torchAvailable else { return }
        scanner.setTorchActive(!scanner.torchActive)
    }

    private func cleanup() {
        scanner.setTorchActive(false)
        scanner.stop()
        UIScreen.main.brightness = previousBrightness
    }
}

// MARK: - Camera Preview + Scanner

private struct CameraPreviewView: UIViewRepresentable {
    @ObservedObject var scanner: QRCodeScanner

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = scanner.session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        uiView.videoPreviewLayer.session = scanner.session
    }

    final class PreviewView: UIView {
        override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }

        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            layer as! AVCaptureVideoPreviewLayer
        }
    }
}

final class QRCodeScanner: NSObject, ObservableObject, AVCaptureMetadataOutputObjectsDelegate {
    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.seshi.qrscanner.session")
    private let metadataOutput = AVCaptureMetadataOutput()

    @Published private(set) var torchActive: Bool = false
    @Published private(set) var torchAvailable: Bool = false
    @Published private(set) var authorizationStatus: AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)

    var onPayload: ((QRCodePayload) -> Void)?
    private var isSessionConfigured = false

    func requestPermission(_ completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                self.authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
                completion(granted)
            }
        }
    }

    func start() {
        guard authorizationStatus == .authorized else { return }
        sessionQueue.async {
            if !self.isSessionConfigured {
                self.configureSession()
            }
            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }

    func stop() {
        sessionQueue.async {
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
        setTorchActive(false)
    }

    func setTorchActive(_ active: Bool) {
        sessionQueue.async {
            guard
                let device = AVCaptureDevice.default(for: .video),
                device.hasTorch
            else { return }

            do {
                try device.lockForConfiguration()
                if active && self.session.isRunning {
                    try device.setTorchModeOn(level: AVCaptureDevice.maxAvailableTorchLevel)
                } else {
                    device.torchMode = .off
                }
                device.unlockForConfiguration()
                let hasTorch = device.hasTorch
                DispatchQueue.main.async {
                    self.torchActive = active && self.session.isRunning
                    self.torchAvailable = hasTorch
                }
            } catch {
                DispatchQueue.main.async {
                    self.torchActive = false
                }
            }
        }
    }

    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .high

        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
            let input = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input)
        else {
            session.commitConfiguration()
            return
        }

        session.addInput(input)

        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        }

        let hasTorch = device.hasTorch

        session.commitConfiguration()
        isSessionConfigured = true
        DispatchQueue.main.async {
            self.torchAvailable = hasTorch
        }
    }

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard let readable = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let stringValue = readable.stringValue
        else {
            return
        }

        if let uuid = UUID(uuidString: stringValue) {
            onPayload?(QRCodePayload(id: uuid))
            return
        }

        if let data = stringValue.data(using: .utf8),
           let payload = try? JSONDecoder().decode(QRCodePayload.self, from: data) {
            onPayload?(payload)
        }
    }
}

