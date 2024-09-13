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
    var currentCiImagePublisher: Published<CIImage?>.Publisher {get}
    var currentCiImage: CIImage? {get}
    
    var settingsPublisher: Published<TnCameraSettings>.Publisher {get}
    var settings: TnCameraSettings {get}
    
    var statusPublisher: Published<TnCameraStatus>.Publisher {get}
    var status: TnCameraStatus {get}
    
    func toggleCapturing()
    func startCapturing()
    func stopCapturing()
    func switchCamera()
    
    func captureImage()
    
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
    func setQuality(_ v: AVCapturePhotoOutput.QualityPrioritization)
    func setFocusMode(_ v: AVCaptureDevice.FocusMode)
    
    func setTransport(_ v: TnCameraTransportValue)
}

// MARK: CameraManagerProxyProtocol
public protocol TnCameraProxyProtocol: TnCameraProtocol {
    func setup()
    func send(_ object: TnCameraMessageProtocol, useBle: Bool)
}

extension TnCameraProxyProtocol {
    public func send(_ messageType: TnCameraMessageType, useBle: Bool = false) {
        self.send(TnCameraMessage(messageType), useBle: useBle)
    }

    public func send<T: Codable>(_ messageType: TnCameraMessageType, _ value: T, useBle: Bool = false) {
        self.send(TnCameraMessageValue(messageType, value), useBle: useBle)
    }
    
//    public func getMessageValue<TValue: Codable>(_ receivedMsg: TnMessage) -> TValue? {
//        let msg: TnCameraMessageValue<TValue>? = receivedMsg.toObject()
//        return msg?.value
//    }
//
//    public func solveMsg<TMessage: Codable>(_ receivedMsg: TnMessage, handler: (TMessage) -> Void) {
//        if let msg: TMessage = receivedMsg.toObject() {
//            handler(msg)
//        }
//    }

    public func solveMsgValue<TMessageValue: Codable>(_ receivedMsg: TnMessage, handler: (TMessageValue) -> Void) {
        if let msg: TnCameraMessageValue<TMessageValue> = receivedMsg.toObject() {
            handler(msg.value)
        }
    }
}
