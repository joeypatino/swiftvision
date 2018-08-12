//
//  PageOutlineTracker.swift
//  OpenCVDemo
//
//  Created by Joey Patino on 8/12/18.
//  Copyright © 2018 Joseph Patino. All rights reserved.
//

import Foundation
import SwiftVision

class PageOutlineTracker {
    public var trackingTrigger: ((CGRectOutline) -> ())?
    public var trackingTimeout: TimeInterval = 3.0
    public var pageOutline: CGRectOutline = CGRectOutlineZeroMake() {
        didSet {
            isTracking
                ? continueTracking(outline: pageOutline)
                : startTracking(outline: pageOutline)
        }
    }

    private var trackingErrorCnt: Int = 0
    private let trackingMaxErrorCnt: Int = 3
    private var trackerTimer: Timer?
    private var isTracking: Bool {
        return trackerTimer != nil && CGRectOutlineEquals(pageOutline, CGRectOutlineZeroMake())
    }

    deinit {
        stopTracking()
    }

    private func startTracking(outline: CGRectOutline) {
        guard trackerTimer == nil, !CGRectOutlineEquals(outline, CGRectOutlineZeroMake()) else {
            return
        }
        trackerTimer = Timer.scheduledTimer(timeInterval: trackingTimeout, target: self, selector: #selector(trackerDidTimeout), userInfo: nil, repeats: false)
    }

    private func continueTracking(outline: CGRectOutline) {
        guard trackerTimer != nil else {
            return
        }
        guard !CGRectOutlineEquals(outline, CGRectOutlineZeroMake()) else {
            handleTrackingErr()
            return
        }
        pageOutline = outline
    }

    private func stopTracking() {
        guard trackerTimer != nil else {
            return
        }
        trackerTimer?.invalidate()
        trackerTimer = nil
        trackingErrorCnt = 0
    }

    private func handleTrackingErr() {
        guard trackingErrorCnt < trackingMaxErrorCnt else {
            stopTracking()
            return
        }
        trackingErrorCnt += 1
    }

    @objc private func trackerDidTimeout(_ timer: Timer) {
        trackingTrigger?(pageOutline)
        stopTracking()
    }
}
