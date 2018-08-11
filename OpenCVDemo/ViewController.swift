import UIKit
import SwiftVision

class ViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!
    private let imagePicker = UIImagePickerController()
    private var imageContours = TextDewarper(image: UIImage(named: "boston_cooking_a.jpg")!.normalizedImage())
    private var dewarpedImage: UIImage?
    private let camera = Camera()
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.image = imageContours.inputImage
    }

    @IBAction func originalAction(_ sender: Any) {
        imageView.image = imageContours.inputImage
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
        let viewController = PageCaptureViewController.make(with: camera)
        viewController.delegate = self
        present(viewController, animated: true)
    }

    private func loadImage(_ image:UIImage) {
        dewarpedImage = nil
        imageContours = TextDewarper(image: image.normalizedImage())
        imageView.image = imageContours.inputImage
        dewarpAction(image)
    }
}

extension ViewController: PageCaptureDelegate {
    func captureViewController(_ viewController: PageCaptureViewController, didCapturePage page: UIImage) {
        viewController.dismiss(animated: true)
        loadImage(page)
    }

    func captureViewControllerDidCancel(_ viewController: PageCaptureViewController) {
        viewController.dismiss(animated: true)
    }
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {

        picker.dismiss(animated: true, completion: nil)
        guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else { return }

        loadImage(image)
    }

    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
        guard let image = UIImage(named: "input_image.jpeg") else { return }

        loadImage(image)
    }
}
