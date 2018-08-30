import UIKit
import SwiftVision

class ViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var scrollView: UIScrollView!
    private let imagePicker = UIImagePickerController()
    private var imageContours = TextDewarper(image: UIImage(), configuration: TextDewarperConfiguration())
    private var dewarpedImage: UIImage?
    private let camera = Camera()

    public override var preferredStatusBarStyle: UIStatusBarStyle { return .default }

    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 5.0
        camera.quality = .medium
    }

    @IBAction func originalAction(_ sender: Any) {
        imageView.image = imageContours.inputImage
    }

    @IBAction func processedAction(_ sender: Any) {
        imageView.image = imageContours.renderProcessed()
    }

    @IBAction func outlinesAction(_ sender: Any) {
        imageView.image = imageContours.renderOutlines()
    }

    @IBAction func masksAction(_ sender: Any) {
        imageView.image = imageContours.renderMasks()
    }

    @IBAction func keyPointsAction(_ sender: Any) {
        imageView.image = imageContours.renderKeyPoints()
    }

    @IBAction func curvesAction(_ sender: Any) {
        imageView.image = imageContours.renderTextLineCurves()
    }

    @IBAction func dewarpAction(_ sender: Any) {
        if dewarpedImage == nil {
            self.imageView.image = self.imageContours.inputImage
        }

        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        DispatchQueue.global(qos: .background).async {
            let image = self.imageContours.dewarp()

            DispatchQueue.main.async {
                self.imageView.image = image
                self.dewarpedImage = image
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
        }
    }

    @IBAction private func takePhoto(){
        let viewController = PageCaptureViewController(with: camera)
        viewController.delegate = self
        let navController = UINavigationController(rootViewController: viewController)
        present(navController, animated: true)
    }

    private func loadImage(_ image:UIImage) {
        dewarpedImage = nil
        imageContours = TextDewarper(image: image, configuration: TextDewarperConfiguration())
        imageView.image = imageContours.inputImage
    }
}

extension ViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
}

extension ViewController: PageDetectorDelegate {
    func pageDetectorViewControllerDidCancel(_ viewController: PageDetectorViewController) {
        viewController.dismiss(animated: true)
    }

    func pageDetectorViewController(_ viewController: PageDetectorViewController, didCapturePage page: UIImage) {
        viewController.dismiss(animated: true)
        loadImage(page)
    }
}
