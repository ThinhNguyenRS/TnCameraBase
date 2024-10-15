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
    case reserve_0, reserve_1, reserve_2
    
    case getSettings
    case getSettingsResponse
    
    case getImage
    case getImageResponse

    case getAlbums
    case getAlbumsResponse

    case switchCamera

    case toggleCapturing
    case stopCapturing
    case startCapturing

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

// MARK: TnMessageData
extension TnMessageData {
    var cameraMsgType: TnCameraMessageType? {
        TnCameraMessageType(rawValue: self.typeCode)
    }
}

// MARK: TnTransportableProtocol
extension TnTransportableProtocol {
    public func send(msgType: TnCameraMessageType, to: [String]?) {
        Task {
            try await self.send(typeCode: msgType.rawValue, to: to)
        }
    }

    public func send<T: Codable>(msgType: TnCameraMessageType, value: T, to: [String]?) {
        Task {
            try await self.send(typeCode: msgType.rawValue, value: value, to: to)
        }
    }
    
    public func solveMsgValue<TMessageValue: Codable>(msgData: TnMessageData, handler: (TMessageValue) -> Void) {
        if let msg: TnMessageValue<TMessageValue> = msgData.toObject(decoder: decoder) {
            handler(msg.value)
        }
    }
}

// MARK: TnMessageValue
extension TnMessageValue {
    public init(_ messageType: TnCameraMessageType, _ value: T) {
        self.init(messageType.rawValue, value)
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

// MARK: TnCameraSettingsValue
public struct TnCameraSettingsValue: Codable {
    public let settings: TnCameraSettings?
    public let status: TnCameraStatus?
    public let network: TnNetworkHostInfo?
    
    public init(settings: TnCameraSettings?, status: TnCameraStatus?, network: TnNetworkHostInfo?) {
        self.settings = settings
        self.status = status
        self.network = network
    }
}
