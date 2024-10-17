//
//  extensions.swift
//  TnCameraBase
//
//  Created by Thinh Nguyen on 10/17/24.
//

import Foundation
import CoreMedia
import VideoToolbox
import TnIosBase

extension CMVideoCodecType {
    public static var h264: Self {
        kCMVideoCodecType_H264
    }
    
    public static var hevc: Self {
        kCMVideoCodecType_HEVC
    }
}

