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

protocol PageCaptureDelegate: class {
    func captureViewController(_ viewController: PageCaptureViewController, didCapturePage page: UIImage)
    func captureViewControllerDidCancel(_ viewController: PageCaptureViewController)
}

class PageCaptureViewController: UIViewController {
    @IBOutlet weak var flash: UISwitch!
    @IBOutlet weak var imageView: UIImageView!
    private var pageCapturePreview: PageCapturePreview {
        return view as! PageCapturePreview
    }
    private var pageOutline = CGRectOutlineZeroMake()
    private let pageDetector = PageDetector()
    private var camera: Camera!
    private var timer: Timer?
    weak var delegate: PageCaptureDelegate?
    private var previewType: Int = 0

    public override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        camera.delegate = self
        pageCapturePreview.session = camera.captureSession
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
        timer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(capture), userInfo: nil, repeats: false)
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
        previewType = toggle.selectedSegmentIndex
    }

    private func updatePreview(_ image: UIImage) {
        switch previewType {
        case 0:
            imageView.image = image
        case 1:
            imageView.image = pageDetector.gray(image)
        case 2:
            imageView.image = pageDetector.blurred(image)
        case 3:
            imageView.image = pageDetector.dialate1(image)
        case 4:
            imageView.image = pageDetector.canny(image)
        case 5:
            imageView.image = pageDetector.dialate2(image)
        case 6:
            imageView.image = pageDetector.morph(image)
        default:
            break
        }

        self.imageView.isHidden = false
    }
}

extension PageCaptureViewController: CameraDelegate {
    func camera(_ camera:Camera, didOutput frame: UIImage) {
        DispatchQueue.main.async {
            self.updatePreview(frame)
        }
        return
        let bounds = pageDetector.pageBounds(frame)

        DispatchQueue.main.async {
            self.imageView.image = nil
            self.imageView.isHidden = true
            let previewSize = self.pageCapturePreview.frame.size
            let isValidOutline = !CGRectOutlineEquals(bounds, CGRectOutlineZeroMake())
            let captureOutline = isValidOutline ? bounds : self.pageOutline
            isValidOutline ? self.update() : self.stop()
            isValidOutline ? self.pageOutline = bounds : ()
            self.pageCapturePreview.outline = self.pageDetector.norm2Pix(captureOutline, size: previewSize)
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
