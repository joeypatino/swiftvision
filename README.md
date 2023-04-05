![Swift Version](https://img.shields.io/badge/Swift-5.0-blue)
![Cocoapods platforms](https://img.shields.io/badge/platform-iOS-red)
![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)

# SwiftVision
SwiftVision is a Swift framework for image manipulation that utilizes OpenCV, an open-source computer vision library. It includes a feature for dewarping book pages, allowing them to appear flat.

### Features

- Image manipulation using OpenCV: SwiftVision provides a wide range of image editing functions such as scaling, rotating, blurring, thresholding, and more.
- Dewarping of book pages: SwiftVision's book dewarping feature is based on a model that assumes a book's surface is warped like a cylinder. This model allows a user to take a picture of a book page from various points of view, which can be difficult with other dewarping techniques that require the camera to be strictly parallel to the book surface. 

> A lot of credit for the page dewarping process goes to the great write-up by Matt Zucker: https://mzucker.github.io/2016/08/15/page-dewarping.html.

### Requirements

- iOS 12.0+

## Installation

#### CocoaPods
You can use [CocoaPods](http://cocoapods.org/) to install `SwiftVision` by adding it to your `Podfile`:

```ruby
platform :ios, '12.0'
use_frameworks!
pod 'SwiftVision', :git => 'git@github.com:joeypatino/swiftvision.git'
```

### Usage example

A working example of how to use SwiftVision can be found in the included SwiftVisionDemo app. You can use this demo app to explore the framework's features and see how to implement them in your own project.

### Contributing

Contributions to SwiftVision are welcome! If you find a bug or would like to make an improvement, please report it on the project's GitHub page at https://github.com/joeypatino/swiftvision.

### Meta

Joey Patino – [@nsinvalidarg](https://twitter.com/nsinvalidarg) – joey.patino@pm.me

### License

SwiftVision is released under the MIT License. See the LICENSE file for details.
