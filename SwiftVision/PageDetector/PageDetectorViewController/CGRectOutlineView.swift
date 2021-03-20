internal class CGRectOutlineView: UIView {
    public var outline: CGRectOutline = CGRectOutlineZeroMake() {
        didSet { drawOutline(outline) }
    }

    public var outlineStrokeColor: UIColor = .black {
        didSet {
            shapeLayer?.strokeColor = outlineStrokeColor.cgColor
            drawOutline(outline)
        }
    }

    public var outlineFillColor: UIColor = .init(red: 66/255, green: 134/255, blue: 244/255, alpha: 0.6) {
        didSet {
            shapeLayer?.fillColor = outlineFillColor.cgColor
            drawOutline(outline)
        }
    }

    public var outlineWidth: CGFloat = 2.0 {
        didSet {
            shapeLayer?.lineWidth = outlineWidth
            drawOutline(outline)
        }
    }

    public var cornerRadius: CGFloat = 32.0 {
        didSet {
            shapeLayer?.cornerRadius = cornerRadius
            drawOutline(outline)
        }
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

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }

        ctx.circle(at: outline.topLeft, color: .white, radius: 30)
        ctx.circle(at: outline.topRight, color: .white, radius: 30)
        ctx.circle(at: outline.botRight, color: .white, radius: 30)
        ctx.circle(at: outline.botLeft, color: .white, radius: 30)

        let attributes:[NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 12),
                                                       .foregroundColor: UIColor.red]
        NSString(string:"tl").draw(at: outline.topLeft, withAttributes: attributes)
        NSString(string:"tr").draw(at: outline.topRight, withAttributes: attributes)
        NSString(string:"br").draw(at: outline.botRight, withAttributes: attributes)
        NSString(string:"bl").draw(at: outline.botLeft, withAttributes: attributes)
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

public extension CGContext {
    func circle(at point: CGPoint, color:UIColor, radius: CGFloat) {
        let size = CGSize(width: radius, height: radius)
        let origin = CGPoint(x: point.x - radius/2, y: point.y - radius/2)
        let rect = CGRect(origin: origin, size: size)
        setFillColor(color.cgColor)
        fillEllipse(in: rect)
    }
}
