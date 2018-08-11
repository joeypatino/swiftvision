//
//  Camera.swift
//  OpenCVDemo
//
//  Created by Joey Patino on 8/11/18.
//  Copyright © 2018 Joseph Patino. All rights reserved.
//

import Foundation
import AVFoundation

class Camera {
    public let captureSession = AVCaptureSession()
    public var isFlashEnabled: Bool = false {
        didSet { configureFlash(enabled: isFlashEnabled) }
    }

    private let position = AVCaptureDevice.Position.back
    private let quality = AVCaptureSession.Preset.high
    private var permissionGranted = false
    private let sessionQueue = DispatchQueue(label: "session_queue")

    init() {
        checkPermission()
        sessionQueue.async { [unowned self] in
            self.configureSession()
            self.captureSession.startRunning()
        }
    }

    private func configureFlash(enabled: Bool) {
        do {
            try selectCaptureDevice()?.lockForConfiguration()
            selectCaptureDevice()?.torchMode = enabled ? .on : .off
            selectCaptureDevice()?.unlockForConfiguration()
        } catch {
            print("Torch could not be configured")
        }
    }

    private func configureSession() {
        guard permissionGranted else { return }
        captureSession.sessionPreset = quality

        // setup the camera input device
        guard
            let captureDevice = selectCaptureDevice(),
            let captureDeviceInput = try? AVCaptureDeviceInput(device: captureDevice),
            captureSession.canAddInput(captureDeviceInput)
            else { return }
        captureSession.addInput(captureDeviceInput)
    }

    private func selectCaptureDevice() -> AVCaptureDevice? {
        return AVCaptureDevice.devices().filter { $0.hasMediaType(.video) && $0.position == position }.first
    }

    // MARK: AVSession configuration
    private func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permissionGranted = true
        case .notDetermined:
            requestPermission()
        default:
            permissionGranted = false
        }
    }

    private func requestPermission() {
        sessionQueue.suspend()
        AVCaptureDevice.requestAccess(for: .video) { [unowned self] granted in
            self.permissionGranted = granted
            self.sessionQueue.resume()
        }
    }
}
