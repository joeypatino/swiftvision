//
//  CGRectOutlineView.swift
//  SwiftVision
//
//  Created by Joey Patino on 8/13/18.
//  Copyright © 2018 Joseph Patino. All rights reserved.
//

import UIKit

internal class CGRectOutlineView: UIView {
    public var outline: CGRectOutline = CGRectOutlineZeroMake() {
        didSet { drawOutline(outline) }
    }

    public var outlineStrokeColor: UIColor = .red {
        didSet { drawOutline(outline) }
    }

    public var outlineFillColor: UIColor = .clear {
        didSet { drawOutline(outline) }
    }

    public var outlineWidth: CGFloat = 2.0 {
        didSet { drawOutline(outline) }
    }

    public var cornerRadius: CGFloat = 4.0 {
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
        shapeLayer?.fillColor = outlineFillColor.cgColor
        shapeLayer?.strokeColor = outlineStrokeColor.cgColor
        shapeLayer?.lineWidth = outlineWidth
        shapeLayer?.cornerRadius = cornerRadius
    }

    private func drawOutline(_ outline: CGRectOutline) {
        shapeLayer?.path = path(from: outline)
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
