//
//  TnTranscodingEncoderConfig.swift
//  TnCameraBase
//
//  Created by Thinh Nguyen on 10/17/24.
//

import Foundation
import VideoToolbox

public struct TnTranscodingEncoderConfig {
    public init(
        codecType: CMVideoCodecType = .hevc,
        realTime: Bool = false,
        maximizePowerEfficiency: Bool = false,
        enableHardware: Bool = true,
        prioritizeSpeed: Bool = false,
        enableLowLatencyRateControl: Bool = false
    ) {
        self.codecType = codecType
        self.realTime = realTime
        self.maximizePowerEfficiency = maximizePowerEfficiency
        self.enableHardware = enableHardware
        self.prioritizeSpeed = prioritizeSpeed
        self.enableLowLatencyRateControl = enableLowLatencyRateControl
    }

    public var codecType: CMVideoCodecType
    public var realTime: Bool

    public var prioritizeSpeed: Bool
    public var maximizePowerEfficiency: Bool

    public var enableHardware: Bool
    public var enableLowLatencyRateControl: Bool

    var encoderSpecification: CFDictionary {
        var encoderSpecification: [CFString: CFTypeRef] = [:]

        if #available(iOS 17.4, *) {
            encoderSpecification[
                kVTVideoEncoderSpecification_EnableHardwareAcceleratedVideoEncoder
            ] = enableHardware as CFBoolean

            encoderSpecification[
                kVTVideoEncoderSpecification_RequireHardwareAcceleratedVideoEncoder
            ] = enableHardware as CFBoolean
        }
        
        encoderSpecification[
            kVTVideoEncoderSpecification_EnableLowLatencyRateControl
        ] = enableLowLatencyRateControl as CFBoolean

        return encoderSpecification as CFDictionary
    }

    func apply(to compressionSession: VTCompressionSession) {
        VTSessionSetProperty(
            compressionSession,
            key: kVTCompressionPropertyKey_PrioritizeEncodingSpeedOverQuality,
            value: prioritizeSpeed as CFBoolean
        )

        VTSessionSetProperty(
            compressionSession,
            key: kVTCompressionPropertyKey_RealTime,
            value: realTime as CFBoolean
        )

        VTSessionSetProperty(
            compressionSession,
            key: kVTCompressionPropertyKey_MaximizePowerEfficiency,
            value: maximizePowerEfficiency as CFBoolean
        )
    }
}

extension TnTranscodingEncoderConfig {
    /// Live capture and live broadcast scenarios.
    /// Also set expectedFrameRate to real-time frame rate if possible
    public static let liveCapture = Self(
        realTime: true
    )

    /// Offline transcode initiated by a user, who is waiting for the results
    public static let activeTranscoding = Self(
        realTime: false,
        maximizePowerEfficiency: false
    )

    /// Offline transcode in the background (when the user is not aware)
    public static let backgroundTranscoding = Self(
        realTime: false,
        maximizePowerEfficiency: false
    )

    /// Ultra-low-latency conferencing and cloud gaming (cases where every millisecond counts).
    /// Also set expectedFrameRate to real-time frame rate if possible
    public static let ultraLowLatency = Self(
        realTime: true,
        prioritizeSpeed: true,
        enableLowLatencyRateControl: true
    )
}

