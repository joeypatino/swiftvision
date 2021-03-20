import AVFoundation

public protocol CameraDelegate: class {
    func camera(_ camera:Camera, didOutput frame: UIImage)
}

final public class Camera: NSObject {
    public weak var delegate: CameraDelegate?
    public let captureSession = AVCaptureSession()
    public var isFlashEnabled: Bool = false {
        didSet { configureFlash(enabled: isFlashEnabled) }
    }
    public var quality:AVCaptureSession.Preset = .high {
        didSet { captureSession.sessionPreset = quality }
    }

    private var captureClosure:((UIImage) -> ())?
    private let position = AVCaptureDevice.Position.back
    private var permissionGranted = false
    private let sessionQueue = DispatchQueue(label: "session_queue")
    private let bufferQueue = DispatchQueue(label: "buffer_queue")
    private let context = CIContext()

    private var lastKnownDeviceOrientation: UIDeviceOrientation = .portrait
    private var deviceOrientationObserver: NSObjectProtocol?

    override public init() {
        super.init()
        checkPermission()
        sessionQueue.async { [unowned self] in
            self.configureSession()
            self.captureSession.startRunning()
        }

        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        let center = NotificationCenter.default
        let notification = UIDevice.orientationDidChangeNotification
        deviceOrientationObserver = center.addObserver(forName: notification,
                                                       object: nil, queue: nil, using: deviceOrientationChanged)
    }

    deinit {
        isFlashEnabled = false

        UIDevice.current.endGeneratingDeviceOrientationNotifications()
        deviceOrientationObserver = nil
    }

    private func configureFlash(enabled: Bool) {
        do {
            try selectCaptureDevice()?.lockForConfiguration()
            selectCaptureDevice()?.torchMode = enabled ? .on : .off
            selectCaptureDevice()?.unlockForConfiguration()
        } catch {
            print("Torch could not be configured")
        }
    }

    private func configureSession() {
        guard permissionGranted else { return }
        captureSession.sessionPreset = quality

        // setup the camera input device
        guard
            let captureDevice = selectCaptureDevice(),
            let captureDeviceInput = try? AVCaptureDeviceInput(device: captureDevice),
            captureSession.canAddInput(captureDeviceInput)
            else { return }
        captureSession.addInput(captureDeviceInput)

        // setup the capture data output
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: bufferQueue)
        guard
            captureSession.canAddOutput(videoOutput)
            else { return }
        captureSession.addOutput(videoOutput)

        // configure the output connection
        guard
            let connection = videoOutput.connection(with: .video),
            connection.isVideoOrientationSupported,
            connection.isVideoMirroringSupported
            else { return }

        connection.videoOrientation = .portrait
        connection.isVideoMirrored = position == .front
    }

    private func selectCaptureDevice() -> AVCaptureDevice? {
        return AVCaptureDevice.devices().filter { $0.hasMediaType(.video) && $0.position == position }.first
    }

    // MARK: AVSession configuration
    private func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permissionGranted = true
        case .notDetermined:
            requestPermission()
        default:
            permissionGranted = false
        }
    }

    private func requestPermission() {
        sessionQueue.suspend()
        AVCaptureDevice.requestAccess(for: .video) { [unowned self] granted in
            self.permissionGranted = granted
            self.sessionQueue.resume()
        }
    }

    // MARK: - Public
    public func captureCurrentFrame(captured: @escaping (UIImage) -> ()) {
        self.captureClosure = captured
    }

    @objc private func deviceOrientationChanged(notification: Notification) {
        let allowedOrientations:[UIDeviceOrientation] = [.portrait, .landscapeLeft, .landscapeRight, .portraitUpsideDown]
        guard
            let device = notification.object as? UIDevice,
            allowedOrientations.contains(device.orientation) == true else {
                return
        }
        lastKnownDeviceOrientation = device.orientation
    }
}

extension Camera: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard
            captureSession.isRunning
            else { return }

        guard
            let orientation = UIImage.Orientation(deviceOrientation: lastKnownDeviceOrientation),
            let image = UIImage(cmSampleBuffer: sampleBuffer, context: context, orientation: orientation)
            else { return }

        guard let captured = captureClosure else {
            delegate?.camera(self, didOutput: image)
            return
        }

        captured(image)
        captureClosure = nil
    }
}

extension UIImage {
    convenience init?(cmSampleBuffer sampleBuffer: CMSampleBuffer, context: CIContext = CIContext(), orientation: UIImage.Orientation) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return nil
        }

        let ciImage = CIImage(cvPixelBuffer: imageBuffer).oriented(forExifOrientation: orientation.exif)
        guard
            let cgImage = context._createCGImage(ciImage, from: ciImage.extent)
            else { return nil }

        self.init(cgImage: cgImage)
    }
}

extension UIImage.Orientation {
    init?(deviceOrientation: UIDeviceOrientation) {
        switch deviceOrientation {
        case .portrait: self = .up
        case .portraitUpsideDown: self = .down
        case .landscapeLeft: self = .left
        case .landscapeRight: self = .right
        default: return nil
        }
    }

    var exif: Int32 {
        switch (self) {
        case .up:
            return 1
        case .down:
            return 3
        case .left:
            return 8
        case .right:
            return 6
        case .upMirrored:
            return 2
        case .downMirrored:
            return 4
        case .leftMirrored:
            return 5
        case .rightMirrored:
            return 7
        @unknown default:
            fatalError("unhandled device orientation")
        }
    }
}

extension CIContext {
    /** Manually create the CGImage from CIImage.
     * This works around a memory leak in iOS 9 in the method with the same name
     */
    func _createCGImage(_ image:CIImage, from rect:CGRect) -> CGImage? {
        let width = Int(rect.width)
        let height = Int(rect.height)
        let rawData = UnsafeMutablePointer<UInt8>.allocate(capacity: width * height * 4)
        render(image, toBitmap: rawData, rowBytes: width * 4, bounds: rect, format: CIFormat.RGBA8, colorSpace: CGColorSpaceCreateDeviceRGB())
        guard let dataProvider = CGDataProvider(dataInfo: nil, data: rawData, size: height * width * 4, releaseData: { info, data, size in
            UnsafeRawPointer(data).deallocate()
        }) else { return nil}

        return CGImage(width: width, height: height, bitsPerComponent: 8,
                       bitsPerPixel: 32, bytesPerRow: width * 4,
                       space: CGColorSpaceCreateDeviceRGB(),
                       bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                       provider: dataProvider,
                       decode: nil, shouldInterpolate: false, intent: .defaultIntent)
    }
}
