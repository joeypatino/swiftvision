import UIKit
import SwiftVision

class ViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!
    var imageContours: PageDewarp!

    override func viewDidLoad() {
        super.viewDidLoad()
        let image = UIImage(named: "input_image.jpeg")!
        imageContours = PageDewarp(image: image)
        imageView.image = imageContours.inputImage
    }

    @IBAction func originalAction(_ sender: Any) {
        imageView.image = imageContours.inputImage
    }

    @IBAction func contoursAction(_ sender: Any) {
        imageView.image = imageContours.renderContours()
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
        imageView.image = imageContours.renderPostCorrespondences()
    }

    @IBAction func dewarpAction(_ sender: Any) {
        imageView.image = imageContours.render()
    }
}
