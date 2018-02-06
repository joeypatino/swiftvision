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
        print("start")
        let contours = image.contours()!
        print("found \(contours.count()) contours")

//        for idx in 0..<contours.count() {
//            let contour: Contour = contours[idx]
//            print(contour.size)
//            for p in 0..<contour.size {
//                print(contour.points[p] as? CGPoint)
//            }
//        }
        print("done")
        imageView.image = customMask(img: image)
    }

    private func resize(img: UIImage) -> UIImage {
        return img.resize(to: view.bounds.size)
    }

    private func rect(img: UIImage) -> UIImage {
        return img.rectangle()
    }

    private func customMask(img: UIImage) -> UIImage {
        let thresh = img.threshold(55.0, constant: 25.0)!
        return thresh.dilate(CGSize(width: 14, height: 1)).erode(CGSize(width: 1, height: 5)).elementwiseMinimum(thresh)
    }
}
