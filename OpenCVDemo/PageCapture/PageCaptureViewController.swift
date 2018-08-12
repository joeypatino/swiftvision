//
//  PageCaptureViewController.swift
//  OpenCVDemo
//
//  Created by Joey Patino on 8/9/18.
//  Copyright © 2018 Joseph Patino. All rights reserved.
//

import UIKit
import AVFoundation
import SwiftVision

enum PreviewType: Int {
    case none
    case gray
    case blur
    case dialate1
    case threshhold
    case canny
    case dialate2
}

protocol PageCaptureDelegate: class {
    func captureViewController(_ viewController: PageCaptureViewController, didCapturePage page: UIImage)
    func captureViewControllerDidCancel(_ viewController: PageCaptureViewController)
}

class PageCaptureViewController: UIViewController {
    @IBOutlet weak var flash: UISwitch!
    private var pageCapturePreview: PageCapturePreview {
        return view as! PageCapturePreview
    }
    private var pageOutline = CGRectOutlineZeroMake()
    private let pageDetector = PageDetector()
    private var camera: Camera!
    private var timer: Timer?
    private var previewType: PreviewType = .none
    weak var delegate: PageCaptureDelegate?

    public override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        camera.delegate = self
        camera.quality = .high
        pageCapturePreview.session = camera.captureSession
        let segControl = view.subviews.first(where: { $0 is UISegmentedControl })
        view.bringSubview(toFront: segControl!)

        let toolBar = view.subviews.first(where: { $0 is UIToolbar })
        view.bringSubview(toFront: toolBar!)
    }

    @IBAction func cancelCapture(_ sender: UIBarButtonItem) {
        delegate?.captureViewControllerDidCancel(self)
    }

    @IBAction func flashToggle(_ sender: UISwitch) {
        camera.isFlashEnabled = sender.isOn
    }

    private func update() {
        guard timer == nil else {
            return
        }
        start()
    }

    private func start(){
        guard timer == nil else {
            return
        }
        //timer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(capture), userInfo: nil, repeats: false)
    }

    private func stop() {
        guard timer != nil else {
            return
        }
        timer?.invalidate()
        timer = nil
    }

    @objc private func capture() {
        camera.captureCurrentFrame { [unowned self] frame in
            let image = self.pageDetector.extract(self.pageOutline, from: frame)
            self.delegate?.captureViewController(self, didCapturePage: image ?? frame)
        }
        stop()
    }
}

extension PageCaptureViewController {
    @IBAction func togglePreview(toggle: UISegmentedControl) {
        previewType = PreviewType(rawValue: toggle.selectedSegmentIndex) ?? .none
    }

    private func updatePreview(_ image: UIImage) {
        switch previewType {
        case .none:
            pageCapturePreview.image = nil
        case .gray:
            pageCapturePreview.image = pageDetector.gray(image)
        case .blur:
            pageCapturePreview.image = pageDetector.blurred(image)
        case .dialate1:
            pageCapturePreview.image = pageDetector.dialate1(image)
        case .threshhold:
            pageCapturePreview.image = pageDetector.threshhold(image)
        case .canny:
            pageCapturePreview.image = pageDetector.canny(image)
        case .dialate2:
            pageCapturePreview.image = pageDetector.dialate2(image)
        }
    }
}

extension PageCaptureViewController: CameraDelegate {
    func camera(_ camera:Camera, didOutput frame: UIImage) {
        let bounds = pageDetector.pageBounds(frame)
        DispatchQueue.main.async {
            self.updatePreview(frame)
            let isValidOutline = !CGRectOutlineEquals(bounds, CGRectOutlineZeroMake())
            let captureOutline = isValidOutline ? bounds : self.pageOutline
            let previewSize = self.pageCapturePreview.frame.size

            isValidOutline ? self.update() : self.stop()
            isValidOutline ? self.pageOutline = bounds : ()
            self.pageCapturePreview.outline = isValidOutline
                ? self.pageDetector.norm2Pix(captureOutline, size: previewSize)
                : CGRectOutlineZeroMake()
        }

        /**!
         Consider how to handle "flickering" of the outline? Consider tracking the
         percentage of time that a valid outline is returned within a selected sampling
         interval. If this drops too low, then reset the extraction timeout.
         */
    }
}

extension PageCaptureViewController {
    static func make(with camera: Camera) -> PageCaptureViewController {
        let storyBoard = UIStoryboard(name: "Main", bundle: Bundle.main)
        guard let viewController = storyBoard.instantiateViewController(withIdentifier: "PageCaptureViewController") as? PageCaptureViewController
            else { preconditionFailure() }
        viewController.camera = camera
        return viewController
    }
}
