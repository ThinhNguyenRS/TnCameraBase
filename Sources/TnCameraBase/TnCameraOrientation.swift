//
//  File.swift
//  
//
//  Created by Thinh Nguyen on 9/5/24.
//

import Foundation
import AVFoundation
import SwiftUI

public enum TnCameraOrientation: Int, Codable {
    case portrait = 1
    case portraitUpsideDown = 2
    case landscapeRight = 3
    case landscapeLeft = 4
    
    public static func fromVideoOrientation(_ v: AVCaptureVideoOrientation) -> Self {
        Self(rawValue: v.rawValue)!
    }

    public func toVideoOrientation() -> AVCaptureVideoOrientation {
        AVCaptureVideoOrientation(rawValue: self.rawValue)!
    }
    
    public static func fromAngle(_ v: CGFloat) -> Self {
        if v == 90 {
            .portrait
        } else if v == -90 {
            .portraitUpsideDown
        }
        else if v == 180 {
            .landscapeRight
        }
        else if v == 180 {
            .landscapeLeft
        }
        else {
            Self.portrait
        }
    }
    
    public static func fromUI(_ v: UIDeviceOrientation) -> Self {
        if v.rawValue >= 1 && v.rawValue <= 4 {
            Self(rawValue: v.rawValue)!
        } else {
            .portrait
        }
    }

    public func toAngle() -> CGFloat {
        switch self {
        case .portrait:
            90
        case .portraitUpsideDown:
            -90
        case .landscapeRight:
            180
        case .landscapeLeft:
            -180
        }
    }
}
