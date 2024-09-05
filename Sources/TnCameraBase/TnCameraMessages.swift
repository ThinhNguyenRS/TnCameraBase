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
import TnIosPackage

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
}

public protocol TnCameraMessageProtocol: TnMessageProtocol {
    var messageType: TnCameraMessageType { get }
}

extension TnCameraMessageProtocol {
    public var typeCode: UInt8 {
        messageType.rawValue
    }
}

public struct TnCameraMessage: TnCameraMessageProtocol {
    public let messageType: TnCameraMessageType
    
    public init(_ messageType: TnCameraMessageType) {
        self.messageType = messageType
    }
}

public struct TnCameraMessageValue<T: Codable>: TnCameraMessageProtocol {
    public let messageType: TnCameraMessageType
    public let value: T
    
    public init(_ messageType: TnCameraMessageType, _ value: T) {
        self.messageType = messageType
        self.value = value
    }
}


public struct TnCameraMessageSettingsResponse: TnCameraMessageProtocol {
    public var messageType: TnCameraMessageType {.getSettingsResponse}

    let settings: TnCameraSettings
    let status: CameraStatus

    let ipHost: String?
    let ipPort: UInt16?

    init(settings: TnCameraSettings, status: CameraStatus, network: TnNetwork? = nil) {
        self.settings = settings
        self.status = status
        self.ipHost = network?.host
        self.ipPort = network?.port
    }
}

public struct TnCameraMessageImageResponse: TnCameraMessageProtocol {
    public var messageType: TnCameraMessageType {.getImageResponse}
    let jpegData: Data?
    
    init(jpegData: Data) {
        self.jpegData = jpegData
    }
    
    init(uiImage: UIImage?, scale: CGFloat, compressionQuality: CGFloat) {
        jpegData = uiImage?.jpegData(scale: scale, compressionQuality: compressionQuality)
    }
    
    init(ciImage: CIImage?, scale: CGFloat, compressionQuality: CGFloat) {
        jpegData = ciImage?.jpegData(scale: scale, compressionQuality: compressionQuality)
    }
}

public struct TnCameraMessageSetZoomFactorRequest: TnCameraMessageProtocol {
    public var messageType: TnCameraMessageType {.setZoomFactor}
    let value: CGFloat
    let adjust: Bool
    let withRate: Float
}

