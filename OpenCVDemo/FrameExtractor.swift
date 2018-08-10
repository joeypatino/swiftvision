//
//  FrameExtractor.swift
//  OpenCVDemo
//
//  Created by Joey Patino on 8/9/18.
//  Copyright © 2018 Joseph Patino. All rights reserved.
//

import UIKit
import AVFoundation

protocol FrameExtractorDelegate: class {
    func frameExtractor(_ extractor:FrameExtractor, didOutput frame: UIImage)
}

class FrameExtractor: NSObject {

    private let position = AVCaptureDevice.Position.back
    private let quality = AVCaptureSession.Preset.medium

    private var useFlash: Bool = true
    private var isReadyToCapture:Bool {
        return
            selectCaptureDevice()?.isAdjustingWhiteBalance == false &&
            selectCaptureDevice()?.isAdjustingExposure == false
    }
    private var permissionGranted = false
    private let sessionQueue = DispatchQueue(label: "session_queue")
    private let bufferQueue = DispatchQueue(label: "buffer_queue")
    private let captureSession = AVCaptureSession()
    private let context = CIContext()
    private var captureClosure:((UIImage) -> ())?
    weak var delegate: FrameExtractorDelegate?

    override init() {
        super.init()
        configureFlash(enabled:useFlash)
        checkPermission()
        sessionQueue.async { [unowned self] in
            self.configureSession()
            self.captureSession.startRunning()
        }
    }

    deinit {
        configureFlash(enabled:false)
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

    public func captureCurrentFrame(with quality: AVCaptureSession.Preset = .high, captured: @escaping (UIImage) -> ()) {
        captureSession.sessionPreset = quality
        self.captureClosure = {[weak self] image in
            captured(image)
            self?.endCaptureCurrentFrame()
        }
    }

    private func endCaptureCurrentFrame() {
        captureSession.stopRunning()
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

        // setup the capture data output
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: bufferQueue)
        guard
            captureSession.canAddOutput(videoOutput)
            else { return }
        captureSession.addOutput(videoOutput)

        // configure the output connection
        guard
            let connection = videoOutput.connection(with: .video),
            connection.isVideoOrientationSupported,
            connection.isVideoMirroringSupported
            else { return }

        connection.videoOrientation = .portrait
        connection.isVideoMirrored = position == .front
    }

    private func selectCaptureDevice() -> AVCaptureDevice? {
        return AVCaptureDevice.devices().filter { $0.hasMediaType(.video) && $0.position == position }.first
    }

    // MARK: Sample buffer to UIImage conversion
    private func imageFromSampleBuffer(sampleBuffer: CMSampleBuffer) -> UIImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

extension FrameExtractor: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let image = imageFromSampleBuffer(sampleBuffer: sampleBuffer), isReadyToCapture else { return }
        DispatchQueue.main.async { [unowned self] in
            guard let captured = self.captureClosure else {
                self.delegate?.frameExtractor(self, didOutput: image)
                return
            }
            captured(image)
        }
    }
}
