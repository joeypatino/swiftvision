//
//  CameraPreview.swift
//  SwiftVision
//
//  Created by Joey Patino on 8/13/18.
//  Copyright © 2018 Joseph Patino. All rights reserved.
//

import UIKit
import AVFoundation

open class CameraPreview: UIView {
    public var session: AVCaptureSession? {
        get { return videoPreviewLayer.session }
        set { videoPreviewLayer.session = newValue }
    }

    private var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }

    override open class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        videoPreviewLayer.videoGravity = .resizeAspectFill
    }
}
