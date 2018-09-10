//
//  PageDetectorViewController.swift
//  SwiftVision
//
//  Created by Joey Patino on 8/13/18.
//  Copyright © 2018 Joseph Patino. All rights reserved.
//

import UIKit
import AVFoundation
import Vision

public protocol PageDetectorDelegate: class {
    func pageDetectorViewController(_ viewController: PageDetectorViewController, didCapturePage page: UIImage)
}

final public class PageDetectorViewController: CameraViewController {
    public weak var pageDetectionDelegate: PageDetectorDelegate?
    public var preview: PageDetectorPreview {
        return view as! PageDetectorPreview
    }

    public var legacyPageDetection: Bool = false
    public var minimumAspectRatio: Float = 0.5
    public var maximumAspectRatio: Float = 1.0
    public var quadratureTolerance: Float = 30
    public var minimumSize: Float = 0.2

    private let detector = PageDetector()
    private let tracker = PageOutlineTracker()

    open class var previewClass: UIView.Type {
        return PageDetectorPreview.self
    }

    open override func loadView() {
        view = type(of: self).previewClass.init()
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        camera.delegate = self
        detector.shouldPostProcess = false
        tracker.trackingTrigger = { [weak self] outline in
            self?.capturePage(with: outline)
        }
    }

    private func capturePage(with outline: CGRectOutline) {
        camera.captureCurrentFrame { [weak self] frame in
            let image = self?.detector.extract(outline, from: frame)
            DispatchQueue.main.async {
                guard let weakSelf = self else { return }
                weakSelf.pageDetectionDelegate?.pageDetectorViewController(weakSelf, didCapturePage: image ?? frame)
            }
        }
    }
}

extension PageDetectorViewController: CameraDelegate {
    public func camera(_ camera:Camera, didOutput frame: UIImage) {
        if #available(iOS 11.0, *), legacyPageDetection == false {
            findPageOutline(in: frame)
        } else {
            let outline = detector.pageOutline(frame)
            DispatchQueue.main.async {
                self.tracker.pageOutline = outline
                self.preview.outline = self.detector.denormalize(self.tracker.pageOutline, with: self.preview.frame.size)
            }
        }
    }
}

@available(iOS 11.0, *)
extension PageDetectorViewController {

    private func findPageOutline(in frame: UIImage) {
        guard let ciImage = CIImage(image: frame) else {
            return
        }

        let detectRequest = VNDetectRectanglesRequest(completionHandler: didDetectRectangle())
        detectRequest.minimumConfidence = 0.8
        detectRequest.minimumSize = minimumSize
        detectRequest.quadratureTolerance = quadratureTolerance
        detectRequest.minimumAspectRatio = minimumAspectRatio

        let handler = VNImageRequestHandler(ciImage: ciImage)
        DispatchQueue.global(qos: .userInteractive).async {
            try? handler.perform([detectRequest])
        }
    }

    private func didDetectRectangle() -> VNRequestCompletionHandler {
        return {
            request, error in
            let error = {
                DispatchQueue.main.async {
                    self.tracker.pageOutline = CGRectOutlineZeroMake()
                    self.preview.outline = CGRectOutlineZeroMake()
                }
            }
            guard
                let results = request.results as? [VNRectangleObservation],
                let detectedRectangle = results.first else {
                    error()
                    return
            }
            self.handle(detectedRect: detectedRectangle)
        }
    }

    private func handle(detectedRect: VNRectangleObservation) {
        DispatchQueue.main.async {
            let size = self.preview.frame.size
            let outline = self.outline(from: detectedRect, destinationSize: size)
            self.tracker.pageOutline = self.detector.normalize(outline, with: size)
            self.preview.outline = self.detector.denormalize(self.tracker.pageOutline, with: size)
        }
    }

    private func outline(from detectedRect: VNRectangleObservation, destinationSize size: CGSize) -> CGRectOutline {

        let topLeft = detectedRect.topLeft
        let topRight = detectedRect.topRight
        let bottomRight = detectedRect.bottomRight
        let bottomLeft = detectedRect.bottomLeft
        let convert:(CGPoint) -> CGPoint = {
            let transform = CGAffineTransform.identity
                .scaledBy(x: 1, y: -1)
                .translatedBy(x: 0, y: -size.height)
            return CGPoint(x: $0.x * size.width, y: $0.y * size.height).applying(transform)
        }

        return CGRectOutline(topLeft: convert(topLeft),
                             botLeft: convert(bottomLeft),
                             botRight: convert(bottomRight),
                             topRight: convert(topRight))
    }
}
