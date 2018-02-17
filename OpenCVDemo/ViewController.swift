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

        guard let masked = resized.threshold(55.0, constant: 25.0)?
            .dilate(CGSize(width: 14, height: 1))?
            .erode(CGSize(width: 0, height: 5)) else { return }

//        imageView.image = masked.contours(filteredBy: contourFilter).renderMasks()
        imageView.image = masked.contours(filteredBy: contourFilter).render()
    }

    private func contourFilter(contour: Contour) -> Bool {
        let size = contour.bounds.size
        if contour.aspect > 1.25 { return false }
        if size.width < 6 { return false }
        if size.height < 2 { return false }
        if size.height > 32 { return false }
        return true
    }
}
