//
//  TnTranscodingDecoderConfig.swift
//  TnCameraBase
//
//  Created by Thinh Nguyen on 10/17/24.
//

import VideoToolbox
import TnIosBase

public struct TnTranscodingDecoderConfig: Codable {
    public let realTime: Bool?
    public let maximizePowerEfficiency: Bool?
    public let enableHardware: Bool?

    public init(
        realTime: Bool? = nil,
        maximizePowerEfficiency: Bool? = nil,
        enableHardware: Bool? = nil
    ) {
        self.realTime = realTime
        self.maximizePowerEfficiency = maximizePowerEfficiency
        self.enableHardware = enableHardware
    }

    var decoderSpecification: CFDictionary {
        var decoderSpecification: [CFString: CFTypeRef] = [:]
        if let enableHardware, #available(iOS 17.0, *) {
            decoderSpecification[
                kVTVideoDecoderSpecification_EnableHardwareAcceleratedVideoDecoder
            ] = enableHardware as CFBoolean
        }
        
        return decoderSpecification as CFDictionary
    }

    func apply(to decompressionSession: VTDecompressionSession) {
        if let realTime {
            VTSessionSetProperty(
                decompressionSession,
                key: kVTDecompressionPropertyKey_RealTime,
                value: realTime as CFBoolean
            )
        }

        if let maximizePowerEfficiency {
            VTSessionSetProperty(
                decompressionSession,
                key: kVTDecompressionPropertyKey_MaximizePowerEfficiency,
                value: maximizePowerEfficiency as CFBoolean
            )
        }
    }
}

extension TnTranscodingDecoderConfig {
    public static let `default` = Self(realTime: true, maximizePowerEfficiency: true)
}
