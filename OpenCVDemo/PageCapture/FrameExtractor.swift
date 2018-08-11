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
    public weak var delegate: FrameExtractorDelegate?
    private let context = CIContext(options: [kCIContextUseSoftwareRenderer:false])
    private let bufferQueue = DispatchQueue(label: "buffer_queue")
    private let videoOutput = AVCaptureVideoDataOutput()
    private var captureClosure:((UIImage) -> ())?
    private let camera: Camera

    required init(camera: Camera) {
        self.camera = camera
        super.init()
        configure(camera: camera)
    }

    deinit {
        camera.isFlashEnabled = false
        camera.captureSession.removeOutput(videoOutput)
    }

    public func captureCurrentFrame(captured: @escaping (UIImage) -> ()) {
        self.captureClosure = { image in
            captured(image)
        }
    }

    private func configure(camera: Camera) {
        // setup the capture data output
        videoOutput.setSampleBufferDelegate(self, queue: bufferQueue)
        guard
            camera.captureSession.canAddOutput(videoOutput)
            else { return }
        camera.captureSession.addOutput(videoOutput)

        // configure the output connection
        guard
            let connection = videoOutput.connection(with: .video),
            connection.isVideoOrientationSupported,
            connection.isVideoMirroringSupported
            else { return }

        connection.videoOrientation = .portrait

        if !camera.captureSession.isRunning {
            camera.captureSession.startRunning()
        }
    }

    private func shutdown() {
        camera.captureSession.stopRunning()
    }
}

extension FrameExtractor: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let image = sampleBuffer.image(using: context), camera.captureSession.isRunning else { return }
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
