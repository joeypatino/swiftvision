//
//  CaptureViewController.swift
//  OpenCVDemo
//
//  Created by Joey Patino on 8/9/18.
//  Copyright © 2018 Joseph Patino. All rights reserved.
//

import UIKit
import AVFoundation
import SwiftVision

class CaptureViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!
    let pageDetector = PageDetector()
    let extractor = FrameExtractor()
    var cameraView:CameraView {
        return view as! CameraView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        //cameraView.delegate = self
        extractor.delegate = self
    }

    @IBAction func cancelCapture(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
}

extension CaptureViewController: FrameExtractorDelegate {
    func frameExtractor(_ extractor:FrameExtractor, didCapture frame: UIImage) {
        guard let debugImage = pageDetector.debug(frame) else { return }
        imageView.image = debugImage
    }
}

extension CaptureViewController: CameraViewDelegate {
    func cameraView(_ cameraView: CameraView, didCapture frame: UIImage) {
        //let info = pageDetector.detectPage(frame)
        //print(info)
        guard let debugImage = pageDetector.debug(frame) else { return }
        imageView.image = debugImage
    }
}
