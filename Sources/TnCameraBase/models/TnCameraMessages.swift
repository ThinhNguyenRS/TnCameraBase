//
//  Messages.swift
//  tCamera
//
//  Created by Thinh Nguyen on 8/17/24.
//

import Foundation
import SwiftUI
import CoreImage
import AVFoundation
import TnIosBase

public enum TnCameraMessageType: UInt8, Codable {
    case getSettings
    case getSettingsResponse

//    case setSettingsRequest

    case getImage
    case getImageResponse

    case switchCamera

    case toggleCapturing

    case setLivephoto
    case setFlash
    case setHDR

    case setDepth
    case setPortrait

    case setPreset
    case setCameraType
    
    case setZoomFactor
    case setExposureMode
    case setExposure
    case setQuality
    case setFocusMode

    case captureImage
    
    case setTransport
}

// MARK: TnCameraMessageProtocol
public protocol TnCameraMessageProtocol: TnMessageProtocol {
    var messageType: TnCameraMessageType { get }
}

extension TnCameraMessageProtocol {
    public var typeCode: UInt8 {
        messageType.rawValue
    }
}

// MARK: TnCameraMessage
public struct TnCameraMessage: TnCameraMessageProtocol {
    public let messageType: TnCameraMessageType
    
    public init(_ messageType: TnCameraMessageType) {
        self.messageType = messageType
    }
}

// MARK: TnCameraMessageValue
public struct TnCameraMessageValue<T: Codable>: TnCameraMessageProtocol {
    public let messageType: TnCameraMessageType
    public let value: T
    
    public init(_ messageType: TnCameraMessageType, _ value: T) {
        self.messageType = messageType
        self.value = value
    }
}

// MARK: TnCameraSettingsValue
public struct TnCameraSettingsValue: Codable {
    public let settings: TnCameraSettings
    public let status: TnCameraStatus

    public let ipHost: String?
    public let ipPort: UInt16?

    public init(settings: TnCameraSettings, status: TnCameraStatus, network: TnNetwork? = nil) {
        self.settings = settings
        self.status = status
        self.ipHost = network?.host
        self.ipPort = network?.port
    }
}

// MARK: TnCameraZoomFactorValue
public struct TnCameraZoomFactorValue: Codable {
    public let value: CGFloat
    public let adjust: Bool
    public let withRate: Float
    
    public init(value: CGFloat, adjust: Bool = false, withRate: Float = 1) {
        self.value = value
        self.adjust = adjust
        self.withRate = withRate
    }
}

public struct TnCameraTransportValue: Codable {
    public let maxWidth: CGFloat?
    public let compressQuality: CGFloat?
    public let continuous: Bool?
    
    public init(maxWidth: CGFloat? = nil, compressQuality: CGFloat? = nil, continuous: Bool? = nil) {
        self.maxWidth = maxWidth
        self.compressQuality = compressQuality
        self.continuous = continuous
    }
}

public struct TnCameraExposureValue: Codable {
    public let iso: Float?
    public let duration: Double?
    
    public init(iso: Float? = nil, duration: Double? = nil) {
        self.iso = iso
        self.duration = duration
    }
}
