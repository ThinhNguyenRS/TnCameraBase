//
//  CameraBluetoothServer.swift
//  tCamera
//
//  Created by Thinh Nguyen on 8/19/24.
//

import Foundation
import SwiftUI
import Combine
import AVFoundation
import CoreImage
import TnIosBase

public class TnCameraProxyServer: TnLoggable {
    public let LOG_NAME = "TnCameraProxyServer"

    private let cameraLocal: TnCameraLocal
    private var network: TnNetworkServer?
    private let ble: TnBluetoothServer

    public init(_ cameraManager: TnCameraLocal, networkInfo: TnNetworkServiceInfo) {
        self.cameraLocal = cameraManager
        ble = .init(info: networkInfo)
        if let address = TnNetworkHelper.getAddressList(for: [.wifi, .cellularBridge, .cellular]).first {
            network = .init(host: address.address, port: 1234, queue: .main, delegate: self, EOM: networkInfo.EOM, MTU: networkInfo.MTU)
            network?.start()
        }
        
        logDebug("inited")
    }
    
    public var bleDelegate: TnBluetoothServerDelegate? {
        get {
            ble.delegate
        }
        set {
            ble.delegate = newValue
        }
    }
    
    public var captureCompletion: ((UIImage) -> Void)? {
        get {
            cameraLocal.captureImageCompletion
        }
        set {
            cameraLocal.captureImageCompletion = newValue
        }
    }

}

// MARK: TnBluetoothServerDelegate
extension TnCameraProxyServer: TnBluetoothServerDelegate {
    public func tnBluetoothServer(ble: TnBluetoothServer, statusChanged: TnBluetoothServer.Status) {
        switch statusChanged {
        case .inited:
            ble.start()
        case .started:
            cameraLocal.startCapturing()
        default:
            return
        }
    }
    
    public func tnBluetoothServer(ble: TnBluetoothServer, sentIDs: [String], sentData: Data) {
    }

    public func tnBluetoothServer(ble: TnBluetoothServer, receivedID: String, receivedData: Data) {
        solveData(data: receivedData)
    }
}

extension TnCameraProxyServer {
    public func send(_ object: TnCameraMessageProtocol, useBle: Bool = false) {
        if useBle {
            try? ble.send(object: object)
        } else {
            try? network?.send(object: object)
        }
    }
    
    public func sendImage() {
        if let currentCiImage = cameraLocal.currentCiImage {
            send(.getImageResponse, currentCiImage.jpegData(scale: settings.transportScale, compressionQuality: settings.transportCompressQuality))
        }
    }
    
    func solveData(data: Data) {
        let receivedMsg = TnMessage(data: data)
        let messageType: TnCameraMessageType = .init(rawValue: receivedMsg.typeCode)!
        logDebug("receive", messageType)

        switch messageType {
        case .toggleCapturing:
            toggleCapturing()

        case .switchCamera:
            switchCamera()
            
        case .captureImage:
            captureImage()

        case .getSettings:
            // response settings
            send(.getSettingsResponse, TnCameraSettingsValue(settings: cameraLocal.settings, status: cameraLocal.status, network: network), useBle: true)

        case .getImage:
            sendImage()
            
        case .setZoomFactor:
            solveMsgValue(receivedMsg) { (v: TnCameraZoomFactorValue) in
                setZoomFactor(v)
            }

        case .setLivephoto:
            solveMsgValue(receivedMsg) { (v: Bool) in
                setLivephoto(v)
            }
            
        case .setFlash:
            solveMsgValue(receivedMsg) { (v: AVCaptureDevice.FlashMode) in
                setFlash(v)
            }

        case .setHDR:
            solveMsgValue(receivedMsg) { (v: TnTripleState) in
                setHDR(v)
            }

        case .setPreset:
            solveMsgValue(receivedMsg) { (v: AVCaptureSession.Preset) in
                setPreset(v)
            }
            
        case .setCameraType:
            solveMsgValue(receivedMsg) { (v: AVCaptureDevice.DeviceType) in
                setCameraType(v)
            }
            
        case .setQuality:
            solveMsgValue(receivedMsg) { (v: AVCapturePhotoOutput.QualityPrioritization) in
                setQuality(v)
            }
            
        case .setFocusMode:
            solveMsgValue(receivedMsg) { (v: AVCaptureDevice.FocusMode) in
                setFocusMode(v)
            }

        case .setTransport:
            solveMsgValue(receivedMsg) { (v: TnCameraTransportValue) in
                setTransport(v)
            }
        default:
            return
        }
    }
}

// MARK: CameraManagerProtocol
extension TnCameraProxyServer: TnCameraProxyProtocol {
    public func setup() {
        ble.setupBle()
    }
    
    public var currentCiImagePublisher: Published<CIImage?>.Publisher {
        cameraLocal.currentCiImagePublisher
    }
    
    public var currentCiImage: CIImage? {
        cameraLocal.currentCiImage
    }
    
    public var settingsPublisher: Published<TnCameraSettings>.Publisher {
        cameraLocal.settingsPublisher
    }
    
    public var settings: TnCameraSettings {
        cameraLocal.settings
    }
    
    public var statusPublisher: Published<TnCameraStatus>.Publisher {
        cameraLocal.statusPublisher
    }
    
    public var status: TnCameraStatus {
        cameraLocal.status
    }
    public func startCapturing() {
        cameraLocal.startCapturing()
    }
    
    public func stopCapturing() {
        cameraLocal.stopCapturing()
    }

    public func toggleCapturing() {
        cameraLocal.toggleCapturing()
    }
    
    public func switchCamera() {
        cameraLocal.switchCamera()
    }
    
    public func captureImage() {
        cameraLocal.captureImage()
    }
    
    public func setLivephoto(_ v: Bool) {
        cameraLocal.setLivephoto(v)
    }
    
    public func setFlash(_ v: AVCaptureDevice.FlashMode) {
        cameraLocal.setFlash(v)
    }
    
    public func setHDR(_ v: TnTripleState) {
        cameraLocal.setHDR(v)
    }
    
    public func setPreset(_ v: AVCaptureSession.Preset) {
        cameraLocal.setPreset(v)
    }
    
    public func setCameraType(_ v: AVCaptureDevice.DeviceType) {
        cameraLocal.setCameraType(v)
    }
    
    public func setExposureMode(_ v: AVCaptureDevice.ExposureMode) {
        cameraLocal.setExposureMode(v)
    }
    
    public func setExposure(_ v: TnCameraExposureValue) {
        cameraLocal.setExposure(v)
    }
    
    public func setZoomFactor(_ v: TnCameraZoomFactorValue) {
        cameraLocal.setZoomFactor(v)
    }
    
    public func setDepth(_ v: Bool) {
        cameraLocal.setDepth(v)
    }
    
    public func setPortrait(_ v: Bool) {
        cameraLocal.setPortrait(v)
    }
    
    public func setQuality(_ v: AVCapturePhotoOutput.QualityPrioritization) {
        cameraLocal.setQuality(v)
    }
    
    public func setFocusMode(_ v: AVCaptureDevice.FocusMode) {
    }
    
    public func setTransport(_ v: TnCameraTransportValue) {
        cameraLocal.setTransport(v)
    }
}

extension TnCameraProxyServer: TnNetworkDelegateServer {
    public func tnNetworkReady(_ server: TnNetworkServer) {
    }
    
    public func tnNetworkStop(_ server: TnNetworkServer, error: (any Error)?) {
        network = nil
    }
    
    public func tnNetwork(_ server: TnNetworkServer, accepted: TnNetworkConnectionServer) {
    }
    
    public func tnNetwork(_ server: TnNetworkServer, stopped: TnNetworkConnectionServer, error: (any Error)?) {
    }
    
    public func tnNetwork(_ server: TnNetworkServer, connection: TnNetworkConnection, receivedData: Data) {
        self.solveData(data: receivedData)
    }
    
    public func tnNetwork(_ server: TnNetworkServer, connection: TnNetworkConnection, sentData: Data) {
    }
}
