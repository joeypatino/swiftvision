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
    func pageDetectorViewControllerDidCancel(_ viewController: PageDetectorViewController)
}

open class PageDetectorViewController: UIViewController {
    public weak var delegate: PageDetectorDelegate?
    public var preview: PageDetectorPreview {
        return view as! PageDetectorPreview
    }
    public let camera: Camera
    public let detector = PageDetector()
    private let tracker = PageOutlineTracker()
    private lazy var done = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(cancel))
    open override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }

    open class var previewClass: UIView.Type {
        return PageDetectorPreview.self
    }

    public init(with camera: Camera) {
        self.camera = camera
        super.init(nibName: nil, bundle: nil)
    }

    required public init?(coder aDecoder: NSCoder) {
        self.camera = Camera()
        super.init(coder: aDecoder)
    }

    open override func loadView() {
        view = type(of: self).previewClass.init()
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        detector.shouldPostProcess = false
        camera.delegate = self
        camera.quality = .high
        preview.session = camera.captureSession
        tracker.trackingTrigger = { [weak self] outline in
            self?.capturePage(with: outline)
        }
        if !camera.captureSession.isRunning {
            camera.captureSession.startRunning()
        }
        setupAppearance()
        navigationItem.leftBarButtonItem = done
    }

    @objc private func cancel(_ sender: UIBarButtonItem) {
        camera.captureSession.stopRunning()
        delegate?.pageDetectorViewControllerDidCancel(self)
    }

    private func capturePage(with outline: CGRectOutline) {
        camera.captureCurrentFrame { [weak self] frame in
            let image = self?.detector.extract(outline, from: frame)
            DispatchQueue.main.async {
                guard let weakSelf = self else { return }
                weakSelf.delegate?.pageDetectorViewController(weakSelf, didCapturePage: image ?? frame)
            }
        }
    }

    private func setupAppearance() {
        done.tintColor = .white
        navigationController?.navigationBar.barStyle = .black
    }
}

extension PageDetectorViewController: CameraDelegate {
    public func camera(_ camera:Camera, didOutput frame: UIImage) {

        if #available(iOS 11.0, *) {
            guard
                let ciImage = CIImage(image: frame),
                let ciImageOrientation = CGImagePropertyOrientation(rawValue: 6) else {
                    return
            }

            let detectRequest = VNDetectRectanglesRequest {
                request, error in
                guard let results = request.results as? [VNRectangleObservation],
                    let detectedRectangle = results.first else {
                        DispatchQueue.main.async {
                            self.tracker.pageOutline = CGRectOutlineZeroMake()
                            self.preview.outline = CGRectOutlineZeroMake()
                        }
                        return
                }

                let topLeft = detectedRectangle.topRight
                let topRight = detectedRectangle.bottomRight
                let bottomRight = detectedRectangle.bottomLeft
                let bottomLeft = detectedRectangle.topLeft
                DispatchQueue.main.async {
                    let convert: ((CGPoint) -> CGPoint) = {
                        let transform = CGAffineTransform.identity
                            .scaledBy(x: 1, y: -1)
                            .translatedBy(x: 0, y: -self.preview.frame.size.height)
                        return self.preview.pointConverted(fromCaptureDevicePoint: $0).applying(transform)
                    }

                    let outline = CGRectOutline(topLeft: convert(topLeft), botLeft: convert(bottomLeft),
                                                botRight: convert(bottomRight), topRight: convert(topRight))
                    let normOutline = self.detector.normalize(outline, with: self.preview.frame.size);
                    self.tracker.pageOutline = normOutline
                    self.preview.outline = self.detector.denormalize(self.tracker.pageOutline, with: self.preview.frame.size)
                }
            }
            detectRequest.minimumConfidence = 0.5
            let handler = VNImageRequestHandler(ciImage: ciImage, orientation: ciImageOrientation)
            DispatchQueue.global(qos: .userInteractive).async {
                do {
                    try handler.perform([detectRequest])
                } catch {
                    print(error)
                }
            }

        } else {
            let outline = detector.pageOutline(frame)
            DispatchQueue.main.async {
                self.tracker.pageOutline = outline
                self.preview.outline = self.detector.denormalize(self.tracker.pageOutline, with: self.preview.frame.size)
            }
        }
    }
}
