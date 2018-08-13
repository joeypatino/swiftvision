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

class PageDetectorPreviewPreprocessed: PageDetectorPreview {
    public var image: UIImage? {
        get { return preview.image }
        set { preview.image = newValue }
    }
    private let preview = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit(){
        preview.backgroundColor = .clear
        preview.frame = bounds
        preview.contentMode = .scaleAspectFill
        preview.autoresizingMask = [.flexibleWidth, .flexibleHeight];
        addSubview(preview)
    }
}

class PageCaptureViewController: PageDetectorViewController {
    private let flashToggle = UISwitch()
    private var previewType: PreviewType = .default

    override open class var previewClass: UIView.Type {
        return PageDetectorPreviewPreprocessed.self
    }

    private var previewView: PageDetectorPreviewPreprocessed? {
        return preview as? PageDetectorPreviewPreprocessed
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        flashToggle.addTarget(self, action: #selector(flashToggle(_:)), for: .valueChanged)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: flashToggle)
    }

    override public func didReceiveFrame(_ frame: UIImage) {
        updatePreview(frame)
    }

    @objc private func flashToggle(_ sender: UISwitch) {
        camera.isFlashEnabled = sender.isOn
    }
}

extension PageCaptureViewController {
    private func updatePreview(_ image: UIImage) {
        switch previewType {
        case .default:
            previewView?.image = nil
        case .preprocessed:
            previewView?.image = detector.process(image)
        }
    }
}
