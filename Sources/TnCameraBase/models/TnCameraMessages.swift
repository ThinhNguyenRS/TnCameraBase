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

    case getAlbums
    case getAlbumsResponse

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
    
    case setTransporting
    case setWideColor
    case setCapturing
    
    case createAlbum
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

// MARK: TnCameraTransportingValue
public struct TnCameraTransportingValue: Codable {
    public var scale: CGFloat
    public var compressQuality: CGFloat
    public var continuous: Bool
    
    public init(scale: CGFloat = 0.25, compressQuality: CGFloat = 0.5, continuous: Bool = false) {
        self.scale = scale
        self.compressQuality = compressQuality
        self.continuous = continuous
    }
}

// MARK: TnCameraExposureValue
public struct TnCameraExposureValue: Codable {
    public var mode: AVCaptureDevice.ExposureMode
    public var iso: Float
    public var duration: Double
    
    public init(mode: AVCaptureDevice.ExposureMode = .autoExpose, iso: Float? = nil, duration: Double? = nil) {
        self.mode = mode
        self.iso = iso ?? 0
        self.duration = duration ?? 0
    }
}

// MARK: TnCameraCapturingValue
public struct TnCameraCapturingValue: Codable {
    public var album: String
    public var delay: Int
    public var count: Int
    public var interval: Int
    
    var delayNanoseconds: UInt64 {
        UInt64(delay*1000_000_000)
    }
    
    var intervalNanoseconds: UInt64 {
        UInt64(interval*1000_000_000)
    }

    public init(album: String = "", delay: Int = 0, count: Int = 1, interval: Int = 0) {
        self.album = album
        self.delay = delay
        self.count = count
        self.interval = interval
    }
    
    public static var `default`: Self {
        .init()
    }
}
