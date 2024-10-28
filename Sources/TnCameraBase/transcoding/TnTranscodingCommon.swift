//
//  TnTranscodingCommon.swift
//  TnCameraBase
//
//  Created by Thinh Nguyen on 10/26/24.
//

import Foundation
import CoreMedia

public enum TnTranscodingCodecType: Int, Codable {
    case h264, hevc
    
    public func toCodecType() -> CMVideoCodecType {
        switch self {
        case .h264:
            kCMVideoCodecType_H264
        case .hevc:
            kCMVideoCodecType_HEVC
        }
    }
}
