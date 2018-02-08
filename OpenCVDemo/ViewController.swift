//
//  ViewController.swift
//  OpenCVDemo
//
//  Created by Joey Patino on 2/5/18.
//  Copyright © 2018 Joseph Patino. All rights reserved.
//

import UIKit
import SwiftVision

class ViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        print(OpenCV.version())
    }

    @IBAction func runAction(_ sender: Any) {
        let image = UIImage(named: "input_image.jpeg")!
        guard let resized = image.resize(to: CGSize(width: 1280, height: 700))
            else { return }

        guard let contours = resized.threshold(55.0, constant: 25.0)?
            .dilate(CGSize(width: 1, height: 14))?
            .erode(CGSize(width: 5, height: 0))?
            .elementwiseMinimum(resized.rectangle()!)?
            .contours() else {
                return
        }

        let intermediateImage = contours.render(filteredBy: { contour in
                let size = contour.bounds.size
                if contour.aspect > 1.25 { return false }
                if size.width < 6 { return false }
                if size.height < 2 { return false }
                if size.height > 32 { return false }

                return true
            })?
            .dilate(CGSize(width: 24, height: 14))?
            .erode(CGSize(width: 5, height: 7))

        imageView.image = intermediateImage?.contours()
            .render(inColor: .white, mode: .fill) { contour in
                return contour.area > 3000
        }
    }

    private func resize(img: UIImage) -> UIImage? {
        return img.resize(to: view.bounds.size)
    }

    private func rect(img: UIImage) -> UIImage? {
        return img.rectangle()
    }

    private func customMask(img: UIImage) -> UIImage? {
        guard let thresh = img.threshold(55.0, constant: 25.0) else {
            return nil
        }

        return thresh
            .dilate(CGSize(width: 14, height: 1))?
            .erode(CGSize(width: 1, height: 5))?
            .elementwiseMinimum(thresh)
    }
}
