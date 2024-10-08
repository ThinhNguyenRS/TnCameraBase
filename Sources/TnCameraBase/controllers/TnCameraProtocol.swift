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
    var albums: [String] { get }
    var delegate: TnCameraDelegate? { get set }
    
    func setup()

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
    func setExposure(_ v: TnCameraExposureValue)
    
    func setDepth(_ v: Bool)
    func setPortrait(_ v: Bool)
    func setPriority(_ v: AVCapturePhotoOutput.QualityPrioritization)
    func setFocusMode(_ v: AVCaptureDevice.FocusMode)
    func setWideColor(_ v: Bool)
    
    func setTransporting(_ v: TnCameraTransportingValue)
    func setCapturing(_ v: TnCameraCapturingValue)
    func createAlbum(_ v: String)
}

// MARK: TnCameraProxyProtocol
public protocol TnCameraProxyProtocol: TnCameraProtocol {
    var decoder: TnDecoder { get }
    func send(_ object: TnCameraMessageProtocol, useBle: Bool)
    func sendImage()
}

extension TnCameraProxyProtocol {
    public func send(_ messageType: TnCameraMessageType, useBle: Bool = false) {
        self.send(TnCameraMessage(messageType), useBle: useBle)
    }

    public func send<T: Codable>(_ messageType: TnCameraMessageType, _ value: T, useBle: Bool = false) {
        self.send(TnCameraMessageValue(messageType, value), useBle: useBle)
    }
    
    public func solveMsgValue<TMessageValue: Codable>(_ receivedMsg: TnMessage, handler: (TMessageValue) -> Void) {
        if let msg: TnCameraMessageValue<TMessageValue> = receivedMsg.toObject(decoder: decoder) {
            handler(msg.value)
        }
    }
}

// MARK: TnCameraDelegate
public protocol TnCameraDelegate {
    func tnCamera(captured: TnCameraPhotoOutput)
    func tnCamera(status: TnCameraStatus)
    func tnCamera(settings: TnCameraSettings)
}
