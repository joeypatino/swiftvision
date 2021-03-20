![Swift Version](https://img.shields.io/badge/Swift-5.0-blue)
![Cocoapods platforms](https://img.shields.io/badge/platform-iOS-red)
![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)

# SwiftVision
<br />
<p align="left">
    SwiftVision is a framework for image dewarping and manipulation, written in Swift and using OpenCV
</p>

> Note: There might be better and more efficient means of image processing / manipulation on iOS. This library was 
written mainly as an experiment in text dewarping using OpenCV but continued to expand to include numerous image
editing functions and various related classes. 

Lots of credit on the page dewarping process goes to the great write-up by Matt Zucker https://mzucker.github.io/2016/08/15/page-dewarping.html
## Requirements

- iOS 9.0+

## Installation

#### CocoaPods
You can use [CocoaPods](http://cocoapods.org/) to install `SwiftVision` by adding it to your `Podfile`:

```ruby
platform :ios, '9.0'
use_frameworks!
pod 'SwiftVision', :git => 'git@github.com:joeypatino/swiftvision.git'
```

## Usage example

A working example can be found in the SwiftVisionDemo app included in the repo. Check out the source code for documentation.

### Meta

Joey Patino – [@nsinvalidarg](https://twitter.com/nsinvalidarg) – joey.patino@protonmail.com

Distributed under the MIT license
