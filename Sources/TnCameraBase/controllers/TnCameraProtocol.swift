//
//  CameraProtocol.swift
//  tCamera
//
//  Created by Thinh Nguyen on 8/17/24.
//

import Foundation
import SwiftUI
import CoreImage
import Combine
import AVFoundation
import TnIosBase

// MARK: TnCameraProtocol
public protocol TnCameraProtocol {
    var currentCiImagePublisher: Published<CIImage?>.Publisher { get async }
    var settingsPublisher: Published<TnCameraSettings>.Publisher { get async }
    var statusPublisher: Published<TnCameraStatus>.Publisher { get async }

    var settings: TnCameraSettings { get async }
    var status: TnCameraStatus { get async }

    func toggleCapturing()
    func startCapturing()
    func stopCapturing()
    func switchCamera()
    
    func captureImage(_ v: TnCameraCaptureValue)
    
    func setLivephoto(_ v: Bool)
    func setFlash(_ v: AVCaptureDevice.FlashMode)
    func setHDR(_ v: TnTripleState)
    func setPreset(_ v: AVCaptureSession.Preset)
    func setCameraType(_ v: AVCaptureDevice.DeviceType)
    func setZoomFactor(_ v: TnCameraZoomFactorValue)
    func setExposureMode(_ v: AVCaptureDevice.ExposureMode)
    func setExposure(_ v: TnCameraExposureValue)
    
    func setDepth(_ v: Bool)
    func setPortrait(_ v: Bool)
    func setPriority(_ v: AVCapturePhotoOutput.QualityPrioritization)
    func setFocusMode(_ v: AVCaptureDevice.FocusMode)
    func setWideColor(_ v: Bool)
    
    func setTransport(_ v: TnCameraTransportValue)
}

// MARK: TnCameraSendMessageProtocol
public protocol TnCameraSendMessageProtocol {
    func send(_ object: TnCameraMessageProtocol, useBle: Bool)
}

extension TnCameraSendMessageProtocol {
    public func send(_ messageType: TnCameraMessageType, useBle: Bool = false) {
        self.send(TnCameraMessage(messageType), useBle: useBle)
    }

    public func send<T: Codable>(_ messageType: TnCameraMessageType, _ value: T, useBle: Bool = false) {
        self.send(TnCameraMessageValue(messageType, value), useBle: useBle)
    }
    
    public func solveMsgValue<TMessageValue: Codable>(_ receivedMsg: TnMessage, handler: (TMessageValue) -> Void) {
        if let msg: TnCameraMessageValue<TMessageValue> = receivedMsg.toObject() {
            handler(msg.value)
        }
    }
}

// MARK: CameraManagerProxyProtocol
public protocol TnCameraProxyProtocol: TnCameraProtocol, TnCameraSendMessageProtocol {
    func setup()
}

