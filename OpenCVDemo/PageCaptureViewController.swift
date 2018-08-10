//
//  PageCaptureViewController.swift
//  OpenCVDemo
//
//  Created by Joey Patino on 8/9/18.
//  Copyright © 2018 Joseph Patino. All rights reserved.
//

import UIKit
import SwiftVision

protocol PageCaptureDelegate: class {
    func captureViewController(_ viewController: PageCaptureViewController, didCapturePage page: UIImage)
}

class PageCaptureViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!
    private var timer: Timer?
    private let pageDetector = PageDetector()
    private let extractor = FrameExtractor()
    weak var delegate: PageCaptureDelegate?
    override func viewDidLoad() {
        super.viewDidLoad()
        extractor.delegate = self
    }

    @IBAction func cancelCapture(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
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
            /**!
             1) use a saved copy of the outline to extract the page
             2) the saved copy should be normalized
             3) it must then be converted back to pixel space before
             calling `self.pageDetector.extractPage(outline, from: frame)`
             */
            let image = self.pageDetector.extractPage(frame)
            self.delegate?.captureViewController(self, didCapturePage: image ?? frame)
        }
        stop()
    }
}

extension PageCaptureViewController: FrameExtractorDelegate {
    func frameExtractor(_ extractor:FrameExtractor, didOutput frame: UIImage) {
        let outline = pageDetector.pageBounds(frame)
        let isValidOutline = !CGRectOutlineEquals(outline, CGRectOutlineMake(.zero, .zero, .zero, .zero))
        let image = pageDetector.renderPageBounds(outline, for: frame)

        isValidOutline ? update() : stop()
        imageView.image = image

        /**!
         1) The outline must be normalized at this point and stored..
         2) the normalized outline should be reused during the final page extractions
         3) Consider how to handle "flickering" of the outline? Consider tracking the
         percentage of time that a valid outline is returned within a selected sampling
         interval. If this drops too low, then reset the extraction timeout.
         */
    }
}
