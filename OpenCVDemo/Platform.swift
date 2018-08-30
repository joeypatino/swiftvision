//
//  Platform.swift
//  SwiftVision
//
//  Created by Joey Patino on 8/8/18.
//  Copyright © 2018 Joseph Patino. All rights reserved.
//

import Foundation

public struct Platform {
    static let isSimulator: Bool = {
        var isSim = false
        #if arch(i386) || arch(x86_64)
        isSim = true
        #endif
        return isSim
    }()
}
