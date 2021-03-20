open class PageDetectorPreview: CameraPreview {
    public var outline: CGRectOutline {
        get { return outlineView.outline }
        set { outlineView.outline = newValue }
    }

    private let outlineView = CGRectOutlineView()

    override public init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        backgroundColor = .white
        outlineView.frame = bounds
        outlineView.autoresizingMask = [.flexibleWidth, .flexibleHeight];
        addSubview(outlineView)
    }
}
