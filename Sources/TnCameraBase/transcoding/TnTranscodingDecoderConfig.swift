//
//  TnTranscodingDecoderConfig.swift
//  TnCameraBase
//
//  Created by Thinh Nguyen on 10/17/24.
//

import VideoToolbox
import TnIosBase

public struct TnTranscodingDecoderConfig {
    public let realTime: Bool
    public let maximizePowerEfficiency: Bool
    public let enableHardware: Bool?

    public init(
        realTime: Bool = false,
        maximizePowerEfficiency: Bool = false,
        enableHardware: Bool? = nil
    ) {
        self.realTime = realTime
        self.maximizePowerEfficiency = maximizePowerEfficiency
        self.enableHardware = enableHardware
    }

    var decoderSpecification: CFDictionary {
        var decoderSpecification: [CFString: CFTypeRef] = [:]
        if #available(iOS 17.0, *) {
            if let enableHardware {
                decoderSpecification[
                    kVTVideoDecoderSpecification_EnableHardwareAcceleratedVideoDecoder
                ] = enableHardware as CFBoolean

//                decoderSpecification[
//                    kVTVideoDecoderSpecification_RequireHardwareAcceleratedVideoDecoder
//                ] = enableHardware as CFBoolean
            }
        }
        
        return decoderSpecification as CFDictionary
    }

    func apply(to decompressionSession: VTDecompressionSession) {
        VTSessionSetProperty(
            decompressionSession,
            key: kVTDecompressionPropertyKey_RealTime,
            value: realTime as CFBoolean
        )

        VTSessionSetProperty(
            decompressionSession,
            key: kVTDecompressionPropertyKey_MaximizePowerEfficiency,
            value: maximizePowerEfficiency as CFBoolean
        )
    }
}
