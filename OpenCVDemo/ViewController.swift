import UIKit
import SwiftVision

class ViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!
    private let imagePicker = UIImagePickerController()
    private var imageContours = PageDewarp(image: UIImage(named: "boston_cooking_a.jpg")!.normalizedImage())
    private var dewarpedImage: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.image = imageContours.inputImage
    }

    @IBAction func originalAction(_ sender: Any) {
        imageView.image = imageContours.inputImage
    }

    @IBAction func contoursAction(_ sender: Any) {
        imageView.image = imageContours.renderContours()
    }

    @IBAction func spansAction(_ sender: Any) {
        imageView.image = imageContours.renderSpans()
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

    @IBAction func preCorrespondencesAction(_ sender: Any) {
        imageView.image = imageContours.renderPreCorrespondences()
    }

    @IBAction func postCorrespondencesAction(_ sender: Any) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        DispatchQueue.global(qos: .background).async {
            let image = self.imageContours.renderPostCorrespondences()

            DispatchQueue.main.async {
                self.imageView.image = image
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
        }
    }

    @IBAction func dewarpAction(_ sender: Any) {
        if dewarpedImage == nil {
            self.imageView.image = self.imageContours.inputImage
        }

        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        DispatchQueue.global(qos: .background).async {
            let image = self.dewarpedImage ?? self.imageContours.render()

            DispatchQueue.main.async {
                self.imageView.image = image
                self.dewarpedImage = image
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
        }
    }

    @IBAction private func takePhoto(){
        imagePicker.sourceType = .camera
        imagePicker.cameraCaptureMode = .photo
        imagePicker.cameraDevice = .rear
        imagePicker.delegate = self
        present(imagePicker, animated: true, completion: nil)
    }

    private func loadImage(_ image:UIImage) {
        dewarpedImage = nil
        imageContours = PageDewarp(image: image.normalizedImage())
        imageView.image = imageContours.inputImage
        dewarpAction(image)
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
