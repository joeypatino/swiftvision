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

class CGRectOutlineView: UIView {
    public var outline: CGRectOutline = CGRectOutlineZeroMake() {
        didSet { drawOutline(outline) }
    }

    public var outlineColor: UIColor = .red {
        didSet { drawOutline(outline) }
    }

    public var outlineWidth: CGFloat = 2.0 {
        didSet { drawOutline(outline) }
    }

    private var shapeLayer: CAShapeLayer? {
        return layer as? CAShapeLayer
    }

    override class var layerClass: AnyClass {
        return CAShapeLayer.self
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        backgroundColor = .clear
        isUserInteractionEnabled = false
        shapeLayer?.fillColor = UIColor.clear.cgColor
        shapeLayer?.strokeColor = outlineColor.cgColor
        shapeLayer?.lineWidth = outlineWidth
    }

    override func draw(_ rect: CGRect) {
        guard shapeLayer == nil else { return }
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        ctx.clear(rect)
        ctx.addPath(path(from: outline))
        ctx.setStrokeColor(outlineColor.cgColor)
        ctx.setLineWidth(outlineWidth)
        ctx.strokePath()
    }

    private func drawOutline(_ outline: CGRectOutline) {
        shapeLayer?.path = path(from: outline)
        setNeedsDisplay()
    }

    private func path(from outline: CGRectOutline) -> CGPath {
        let path = CGMutablePath()
        path.move(to: outline.topLeft)
        path.addLine(to: outline.topRight)
        path.addLine(to: outline.botRight)
        path.addLine(to: outline.botLeft)
        path.closeSubpath()
        return path
    }
}

class PageCapturePreview: UIView {
    public var session: AVCaptureSession? {
        get { return videoPreviewLayer.session }
        set { videoPreviewLayer.session = newValue }
    }
    public var outline: CGRectOutline {
        get { return outlineView.outline }
        set { outlineView.outline = newValue }
    }
    public var image: UIImage? {
        get { return preview.image }
        set { preview.image = newValue }
    }

    private var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
    private let outlineView = CGRectOutlineView()
    private let preview = UIImageView()

    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        videoPreviewLayer.videoGravity = .resizeAspectFill

        preview.backgroundColor = .clear
        preview.frame = bounds
        preview.contentMode = .scaleAspectFill
        preview.autoresizingMask = [.flexibleWidth, .flexibleHeight];
        addSubview(preview)

        outlineView.frame = bounds
        outlineView.autoresizingMask = [.flexibleWidth, .flexibleHeight];
        addSubview(outlineView)
    }
}
