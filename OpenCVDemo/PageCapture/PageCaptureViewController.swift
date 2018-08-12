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
    private let outlineTracker = PageOutlineTracker()
    private let pageDetector = PageDetector()
    private var camera: Camera!
    private var previewType: PreviewType = .none
    weak var delegate: PageCaptureDelegate?

    public override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }

    override func viewDidLoad() {
        super.viewDidLoad()

        camera.delegate = self
        camera.quality = .high
        pageCapturePreview.session = camera.captureSession

        outlineTracker.trackingTrigger = { [weak self] outline in
            self?.capturePage(with: outline)
        }

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

    private func capturePage(with outline: CGRectOutline) {
        camera.captureCurrentFrame { [unowned self] frame in
            let image = self.pageDetector.extract(outline, from: frame)
            self.delegate?.captureViewController(self, didCapturePage: image ?? frame)
        }
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
        let outline = pageDetector.pageBounds(frame)
        DispatchQueue.main.async {
            self.updatePreview(frame)
            self.outlineTracker.pageOutline = outline
            self.pageCapturePreview.outline = self.pageDetector.norm2Pix(self.outlineTracker.pageOutline, size: self.pageCapturePreview.frame.size)
        }
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
