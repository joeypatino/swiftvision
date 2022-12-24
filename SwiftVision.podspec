Pod::Spec.new do |s|
  s.name         = 'SwiftVision'
  s.version      = '0.2.5'
  s.summary      = 'A framework for image dewarping and manipulation.'
  s.homepage     = 'https://www.github.com/joeypatino/swiftvision.git'
  s.description  = <<-DESC
  SwiftVision is a framework to perform image manipulation.
  DESC
  s.license      = { :type => 'MIT', :file => 'LICENSE' }

  s.author       = { 'joey patino' => 'joey.patino@protonmail.com' }
  s.source              = { :git => 'https://github.com/joeypatino/swiftvision.git', :tag => s.version.to_s }

  s.source_files        = 'SwiftVision/**/*.{h,m,mm,hpp,cpp,swift}'
  s.public_header_files = 'SwiftVision/UIImage+OpenCV.h','SwiftVision/TextDewarper/*.h','SwiftVision/PageDetector/*.h','SwiftVision/TextDewarper/models/{Contour,ContourEdge,ContourSpan}.h','SwiftVision/structs/CGRectOutline.h'

  s.frameworks          = 'CoreGraphics','UIKit','AVFoundation','opencv2'
  s.vendored_frameworks = 'opencv2.xcframework'

  s.platform                = :ios
  s.ios.deployment_target   = '9.0'
  s.swift_version           = '4.0'
  
  s.xcconfig = {
     'CLANG_CXX_LANGUAGE_STANDARD' => 'gnu++11',
     'CLANG_CXX_LIBRARY' => 'libc++',
     'GCC_C_LANGUAGE_STANDARD' => 'c11',
     'GCC_INPUT_FILETYPE' => 'automatic',
     'FRAMEWORK_SEARCH_PATHS' => '$(PROJECT_DIR)'
  }
end
