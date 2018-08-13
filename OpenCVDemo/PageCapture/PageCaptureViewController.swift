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
    case `default`
    case preprocessed
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
    private var camera: Camera?
    private var previewType: PreviewType = .default
    weak var delegate: PageCaptureDelegate?

    public override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }

    override func viewDidLoad() {
        super.viewDidLoad()

        camera?.delegate = self
        camera?.quality = .high
        pageCapturePreview.session = camera?.captureSession

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
        camera?.isFlashEnabled = sender.isOn
    }

    private func capturePage(with outline: CGRectOutline) {
        camera?.captureCurrentFrame { [weak self] frame in
            guard let weakSelf = self else { return }
            let image = weakSelf.pageDetector.extract(outline, from: frame)
            weakSelf.delegate?.captureViewController(weakSelf, didCapturePage: image ?? frame)
        }
    }
}

extension PageCaptureViewController {
    @IBAction func togglePreview(toggle: UISegmentedControl) {
        previewType = PreviewType(rawValue: toggle.selectedSegmentIndex) ?? .default
    }

    private func updatePreview(_ image: UIImage) {
        switch previewType {
        case .default:
            pageCapturePreview.image = nil
        case .preprocessed:
            pageCapturePreview.image = pageDetector.process(image)
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
