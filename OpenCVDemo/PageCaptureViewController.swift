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
}

class PageCaptureViewController: UIViewController {
    @IBOutlet weak var flash: UISwitch!
    private var pageCaptureView: PageCaptureView {
        return view as! PageCaptureView
    }
    private var pageOutline = CGRectOutlineZeroMake()
    private let pageDetector = PageDetector()
    private let extractor = FrameExtractor()
    private var timer: Timer?
    weak var delegate: PageCaptureDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        extractor.delegate = self
        pageCaptureView.videoPreviewLayer.session = extractor.captureSession
    }

    public override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }

    @IBAction func cancelCapture(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }

    @IBAction func flashToggle(_ sender: UISwitch) {
        extractor.isFlashEnabled = sender.isOn
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
        extractor.captureCurrentFrame { [unowned self] frame in
            let image = self.pageDetector.extract(self.pageOutline, from: frame)
            self.delegate?.captureViewController(self, didCapturePage: image ?? frame)
        }
        stop()
    }
}

extension PageCaptureViewController: FrameExtractorDelegate {
    func frameExtractor(_ extractor:FrameExtractor, didOutput frame: UIImage) {
        let outline = pageDetector.pageBounds(frame)

        DispatchQueue.main.async {
            let isValidOutline = !CGRectOutlineEquals(outline, CGRectOutlineZeroMake())
            isValidOutline ? self.update() : self.stop()
            if isValidOutline { self.pageOutline = outline }
            let pixOutline = self.pageDetector.norm2Pix(isValidOutline ? outline : self.pageOutline, size: self.pageCaptureView.frame.size)
            self.pageCaptureView.outline = pixOutline
        }

        /**!
         Consider how to handle "flickering" of the outline? Consider tracking the
         percentage of time that a valid outline is returned within a selected sampling
         interval. If this drops too low, then reset the extraction timeout.
         */
    }
}
