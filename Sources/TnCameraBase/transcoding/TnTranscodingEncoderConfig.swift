//
//  TnTranscodingEncoderConfig.swift
//  TnCameraBase
//
//  Created by Thinh Nguyen on 10/17/24.
//

import Foundation
import VideoToolbox

public struct TnTranscodingEncoderConfig: Codable {
    public let codecType: TnTranscodingCodecType
    public let realTime: Bool?
    public let prioritizeSpeed: Bool?
    public let maximizePowerEfficiency: Bool?
    public let enableHardware: Bool?
    public let enableLowLatencyRateControl: Bool?

    public init(
        codecType: TnTranscodingCodecType = .hevc,
        realTime: Bool? = nil,
        maximizePowerEfficiency: Bool? = nil,
        enableHardware: Bool? = nil,
        prioritizeSpeed: Bool? = nil,
        enableLowLatencyRateControl: Bool? = nil
    ) {
        self.codecType = codecType
        self.realTime = realTime
        self.maximizePowerEfficiency = maximizePowerEfficiency
        self.enableHardware = enableHardware
        self.prioritizeSpeed = prioritizeSpeed
        self.enableLowLatencyRateControl = enableLowLatencyRateControl
    }

    var encoderSpecification: CFDictionary {
        var encoderSpecification: [CFString: CFTypeRef] = [:]

        if let enableHardware, #available(iOS 17.4, *) {
            encoderSpecification[
                kVTVideoEncoderSpecification_EnableHardwareAcceleratedVideoEncoder
            ] = enableHardware as CFBoolean
        }
        
        if let enableLowLatencyRateControl {
            encoderSpecification[
                kVTVideoEncoderSpecification_EnableLowLatencyRateControl
            ] = enableLowLatencyRateControl as CFBoolean
        }

        return encoderSpecification as CFDictionary
    }

    func apply(to compressionSession: VTCompressionSession) {
        if let prioritizeSpeed {
            VTSessionSetProperty(
                compressionSession,
                key: kVTCompressionPropertyKey_PrioritizeEncodingSpeedOverQuality,
                value: prioritizeSpeed as CFBoolean
            )
        }

        if let realTime {
            VTSessionSetProperty(
                compressionSession,
                key: kVTCompressionPropertyKey_RealTime,
                value: realTime as CFBoolean
            )
        }

        if let maximizePowerEfficiency {
            VTSessionSetProperty(
                compressionSession,
                key: kVTCompressionPropertyKey_MaximizePowerEfficiency,
                value: maximizePowerEfficiency as CFBoolean
            )
        }
    }
}

extension TnTranscodingEncoderConfig {
    /// Live capture and live broadcast scenarios.
    /// Also set expectedFrameRate to real-time frame rate if possible
    public static let liveCapture = Self(
        codecType: .hevc,
        realTime: true
    )

    /// Offline transcode initiated by a user, who is waiting for the results
    public static let activeTranscoding = Self(
        codecType: .hevc,
        realTime: false,
        maximizePowerEfficiency: false
    )

    /// Offline transcode in the background (when the user is not aware)
    public static let backgroundTranscoding = Self(
        codecType: .hevc,
        realTime: false,
        maximizePowerEfficiency: false
    )

    /// Ultra-low-latency conferencing and cloud gaming (cases where every millisecond counts).
    /// Also set expectedFrameRate to real-time frame rate if possible
    public static let `default` = Self(
        codecType: .hevc
//        realTime: true,
//        maximizePowerEfficiency: true,
//        prioritizeSpeed: true,
//        enableLowLatencyRateControl: true
    )
}

