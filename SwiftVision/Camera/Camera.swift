//
//  Camera.swift
//  OpenCVDemo
//
//  Created by Joey Patino on 8/11/18.
//  Copyright © 2018 Joseph Patino. All rights reserved.
//

import UIKit
import AVFoundation

public protocol CameraDelegate: class {
    func camera(_ camera:Camera, didOutput frame: UIImage)
}

final public class Camera: NSObject {
    public weak var delegate: CameraDelegate?
    public let captureSession = AVCaptureSession()
    public var isFlashEnabled: Bool = false {
        didSet { configureFlash(enabled: isFlashEnabled) }
    }
    public var quality:AVCaptureSession.Preset = .high {
        didSet { captureSession.sessionPreset = quality }
    }

    private var captureClosure:((UIImage) -> ())?
    private let position = AVCaptureDevice.Position.back
    private var permissionGranted = false
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "session_queue")
    private let bufferQueue = DispatchQueue(label: "buffer_queue")
    private let context = CIContext(options: [kCIContextUseSoftwareRenderer:false])

    override public init() {
        super.init()
        checkPermission()
        sessionQueue.async { [unowned self] in
            self.configureSession()
            self.captureSession.startRunning()
        }
    }

    deinit {
        isFlashEnabled = false
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

        // setup the capture data output
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

    // MARK: - Public
    public func captureCurrentFrame(captured: @escaping (UIImage) -> ()) {
        self.captureClosure = { image in
            captured(image)
        }
    }
}

extension Camera: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let image = sampleBuffer.image(using: context), captureSession.isRunning else { return }
        guard let captured = captureClosure else {
            delegate?.camera(self, didOutput: image)
            return
        }
        captured(image)
        captureClosure = nil
    }
}

extension CMSampleBuffer {
    func image(using context: CIContext) -> UIImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(self) else { return nil }
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        guard let cgImage = context._createCGImage(ciImage, from: ciImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

extension CIContext {
    /** Manually create the CGImage from CIImage.
     * This works around a memory leak in iOS 9 in the method with the same name
     */
    func _createCGImage(_ image:CIImage, from rect:CGRect) -> CGImage? {
        let width = Int(rect.width)
        let height = Int(rect.height)
        let rawData = UnsafeMutablePointer<UInt8>.allocate(capacity: width * height * 4)
        render(image, toBitmap: rawData, rowBytes: width * 4, bounds: rect, format: kCIFormatRGBA8, colorSpace: CGColorSpaceCreateDeviceRGB())
        guard let dataProvider = CGDataProvider(dataInfo: nil, data: rawData, size: height * width * 4, releaseData: { info, data, size in
            UnsafeRawPointer(data).deallocate()
        }) else { return nil}

        return CGImage(width: width, height: height, bitsPerComponent: 8,
                       bitsPerPixel: 32, bytesPerRow: width * 4,
                       space: CGColorSpaceCreateDeviceRGB(),
                       bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                       provider: dataProvider,
                       decode: nil, shouldInterpolate: false, intent: .defaultIntent)
    }
}
