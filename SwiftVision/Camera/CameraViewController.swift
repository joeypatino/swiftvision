import AVFoundation

public protocol CameraViewControllerDelegate: class {
    func cameraViewControllerDidCancel(_ viewController: CameraViewController)
}

open class CameraViewController: UIViewController {
    public weak var delegate: CameraViewControllerDelegate?
    public let camera: Camera
    public var overlay: UIView? {
        didSet {
            guard isViewLoaded else { return }
            oldValue?.removeFromSuperview()
            setup(overlay: overlay)
        }
    }

    private lazy var done = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(cancel))
    private lazy var toggle: UIBarButtonItem = {
        let flashToggle = UISwitch()
        flashToggle.addTarget(self, action: #selector(flashToggle(_:)), for: .valueChanged)
        return UIBarButtonItem(customView: flashToggle)
    }()

    private var preview: CameraPreview {
        return view as! CameraPreview
    }
    
    override open var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }

    public init(with camera: Camera) {
        self.camera = camera
        super.init(nibName: nil, bundle: nil)
    }

    public func capture(completion: @escaping (UIImage) -> ()) {
        camera.captureCurrentFrame(captured: completion)
    }

    required public init?(coder aDecoder: NSCoder) {
        self.camera = Camera()
        super.init(coder: aDecoder)
    }

    open override func loadView() {
        let cameraView = CameraPreview()
        cameraView.frame = UIScreen.main.bounds
        view = cameraView
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        setup(overlay: overlay)
        camera.quality = .high
        preview.session = camera.captureSession
        if !camera.captureSession.isRunning {
            camera.captureSession.startRunning()
        }
        navigationItem.leftBarButtonItem = done
        navigationItem.rightBarButtonItem = toggle
    }

    deinit {
        camera.isFlashEnabled = false
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateCameraOrientation()
    }

    override open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        updateCameraOrientation()
    }

    // MARK: - Actions
    @objc private func cancel(_ sender: UIBarButtonItem) {
        camera.captureSession.stopRunning()
        delegate?.cameraViewControllerDidCancel(self)
    }

    @objc private func flashToggle(_ sender: UISwitch) {
        camera.isFlashEnabled = sender.isOn
    }

    // MARK: - Private
    private func setupAppearance() {
        done.tintColor = .white
        navigationController?.navigationBar.barStyle = .black
    }

    private func updateCameraOrientation() {
        guard let connection = preview.cameraConnection else {
            return
        }
        let deviceOrientation = UIDevice.current.orientation
        guard let newOrientation = AVCaptureVideoOrientation(deviceOrientation: deviceOrientation),
            deviceOrientation.isPortrait || deviceOrientation.isLandscape else {
                return
        }
        connection.videoOrientation = newOrientation
    }

    private func setup(overlay: UIView?) {
        overlay.map { view.addSubview($0) }
        overlay?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        overlay?.frame = view.bounds
    }
}
