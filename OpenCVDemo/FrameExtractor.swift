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
    public let captureSession = AVCaptureSession()
    public var isFlashEnabled: Bool = false {
        didSet { configureFlash(enabled: isFlashEnabled) }
    }
    public weak var delegate: FrameExtractorDelegate?

    private let position = AVCaptureDevice.Position.back
    private let quality = AVCaptureSession.Preset.high
    private var permissionGranted = false
    private let sessionQueue = DispatchQueue(label: "session_queue")
    private let bufferQueue = DispatchQueue(label: "buffer_queue")
    private let context = CIContext(options: [kCIContextUseSoftwareRenderer:false])
    private var captureClosure:((UIImage) -> ())?

    override init() {
        super.init()
        checkPermission()
        sessionQueue.async { [unowned self] in
            self.configureSession()
            self.captureSession.startRunning()
        }
    }

    deinit {
        print(#function, self)
        configureFlash(enabled:false)
    }

    public func captureCurrentFrame(captured: @escaping (UIImage) -> ()) {
        self.captureClosure = { image in
            captured(image)
        }
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

    private func configureFlash(enabled: Bool) {
        do {
            try selectCaptureDevice()?.lockForConfiguration()
            selectCaptureDevice()?.torchMode = enabled ? .on : .off
            selectCaptureDevice()?.unlockForConfiguration()
        } catch {
            print("Torch could not be configured")
        }
    }

    private func selectCaptureDevice() -> AVCaptureDevice? {
        return AVCaptureDevice.devices().filter { $0.hasMediaType(.video) && $0.position == position }.first
    }

    private func shutdown() {
        sessionQueue.suspend()
        bufferQueue.suspend()
        captureSession.stopRunning()
    }
}

extension FrameExtractor: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let image = sampleBuffer.image(using: context), captureSession.isRunning else { return }
        guard let captured = captureClosure else {
            delegate?.frameExtractor(self, didOutput: image)
            return
        }
        captured(image)
        captureClosure = nil
        shutdown()
    }
}

extension CMSampleBuffer {
    func image(using context: CIContext) -> UIImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(self) else { return nil }
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

extension CIContext {
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
