//
//  PageCapturePreview.swift
//  OpenCVDemo
//
//  Created by Joey Patino on 8/11/18.
//  Copyright © 2018 Joseph Patino. All rights reserved.
//

import UIKit
import AVFoundation
import SwiftVision

class PageCapturePreview: UIView {
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    public var session: AVCaptureSession? {
        get { return videoPreviewLayer.session }
        set { videoPreviewLayer.session = session }
    }
    public var outline: CGRectOutline = CGRectOutlineZeroMake() {
        didSet { drawOutline(outline) }
    }
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }

    private let outlineLayer = CAShapeLayer()
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        outlineLayer.frame = bounds
    }

    private func commonInit() {
        outlineLayer.frame = bounds
        layer.addSublayer(outlineLayer)
    }

    private func drawOutline(_ outline: CGRectOutline) {
        let path = CGMutablePath()
        path.move(to: outline.topLeft)
        path.addLine(to: outline.topRight)
        path.addLine(to: outline.botRight)
        path.addLine(to: outline.botLeft)
        path.closeSubpath()
        outlineLayer.path = path

        outlineLayer.fillColor = UIColor.clear.cgColor
        outlineLayer.strokeColor = UIColor.red.cgColor
    }
}
