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
//        let image = UIImage(named: "input_image.jpeg")
        let image = UIImage(named: "90550036_edit.jpg")
        let output = OpenCV.resize(image, to: view.bounds.size)
        imageView.image = output
    }
}
