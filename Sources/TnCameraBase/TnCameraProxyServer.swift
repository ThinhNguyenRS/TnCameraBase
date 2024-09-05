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
import TnIosPackage

public class TnCameraProxyServer: TnLoggable {
    public let LOG_NAME = "CameraBluetoothServer"

    private let cameraManager: TnCameraProtocol
    private var network: TnNetworkServer?
    private let ble: TnBluetoothServer

    public init(_ cameraManager: TnCameraProtocol, bluetooth: TnBluetoothServiceInfo) {
        self.cameraManager = cameraManager
        ble = .init(info: bluetooth)
        if let address = TnNetworkHelper.getAddressList(for: [.wifi, .cellularBridge, .cellular]).first {
            network = .init(host: address.address, port: 1234, queue: .main, delegate: self, eom: bluetooth.EOM)
            network?.start()
        }
    }
    
    public var bleDelegate: TnBluetoothServerDelegate? {
        get {
            ble.delegate
        }
        set {
            ble.delegate = newValue
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
            cameraManager.startCapturing(completion: nil)
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
            ble.send(object: object)
        } else {
            network?.send(object: object)
        }
    }
    
    public func sendImage() {
//        send(MsgGetImageResponse(ciImage: cameraManager.currentCiImage, scale: 0.25, compressionQuality: 0.5))
        send(TnCameraMessageImageResponse(ciImage: cameraManager.currentCiImage, scale: 1, compressionQuality: 0.75))
    }
    
    func solveData(data: Data) {
        let receivedMsg = data.toMessage()
        let messageType: TnCameraMessageType = .init(rawValue: receivedMsg.typeCode)!
        TnLogger.debug(LOG_NAME, "receive", messageType)

        switch messageType {
        case .toggleCapturing:
            cameraManager.toggleCapturing { [self] in
                send(TnCameraMessageSettingsResponse(settings: cameraManager.settings, status: cameraManager.status))
            }

        case .switchCamera:
            cameraManager.switchCamera { [self] in
                send(TnCameraMessageSettingsResponse(settings: cameraManager.settings, status: cameraManager.status))
            }
            
        case .captureImage:
            cameraManager.captureImage(completion: { [self] uiImage in
                TnLogger.debug(LOG_NAME, "captured image", uiImage.size.width, uiImage.size.height)
                send(TnCameraMessageImageResponse(uiImage: uiImage, scale: 0.9, compressionQuality: 0.9))
            })

        case .getSettings:
            // response settings
            send(TnCameraMessageSettingsResponse(settings: cameraManager.settings, status: cameraManager.status, network: network), useBle: true)

        case .getImage:
            sendImage()
            
        case .setZoomFactor:
            let msg: TnCameraMessageSetZoomFactorRequest = receivedMsg.toObject()!
            cameraManager.setZoomFactor(msg.value, adjust: msg.adjust, withRate: msg.withRate) { [self] in
                send(TnCameraMessageSettingsResponse(settings: cameraManager.settings, status: cameraManager.status))
            }
            
        case .setLivephoto:
            cameraManager.setLivephoto(getMessageValue(receivedMsg))
            
        case .setFlash:
            cameraManager.setFlash(getMessageValue(receivedMsg))

        case .setHDR:
            cameraManager.setHDR(getMessageValue(receivedMsg))

        case .setPreset:
            cameraManager.setPreset(getMessageValue(receivedMsg))
            
        case .setCameraType:
            cameraManager.setCameraType(getMessageValue(receivedMsg))
            
        case .setQuality:
            cameraManager.setQuality(getMessageValue(receivedMsg))
            
        case .setFocusMode:
            cameraManager.setFocusMode(getMessageValue(receivedMsg))

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
        cameraManager.currentCiImagePublisher
    }
    
    public var currentCiImage: CIImage? {
        cameraManager.currentCiImage
    }
    
    public var settingsPublisher: Published<TnCameraSettings>.Publisher {
        cameraManager.settingsPublisher
    }
    
    public var settings: TnCameraSettings {
        cameraManager.settings
    }
    
    public var statusPublisher: Published<CameraStatus>.Publisher {
        cameraManager.statusPublisher
    }
    
    public var status: CameraStatus {
        cameraManager.status
    }
    public func startCapturing(completion: (() -> Void)?) {
        cameraManager.startCapturing(completion: completion)
    }
    
    public func stopCapturing(completion: (() -> Void)?) {
        cameraManager.stopCapturing(completion: completion)
    }

    public func toggleCapturing(completion: (() -> Void)?) {
        cameraManager.toggleCapturing(completion: completion)
    }
    
    public func switchCamera(completion: (() -> Void)?) {
        cameraManager.switchCamera(completion: completion)
    }
    
    public func captureImage(completion: @escaping (UIImage) -> Void) {
        cameraManager.captureImage(completion: completion)
    }
    
    public func setLivephoto(_ v: Bool) {
        cameraManager.setLivephoto(v)
    }
    
    public func setFlash(_ v: AVCaptureDevice.FlashMode) {
        cameraManager.setFlash(v)
    }
    
    public func setHDR(_ v: TnTripleState) {
        cameraManager.setHDR(v)
    }
    
    public func setPreset(_ v: AVCaptureSession.Preset) {
        cameraManager.setPreset(v)
    }
    
    public func setCameraType(_ v: AVCaptureDevice.DeviceType) {
        cameraManager.setCameraType(v)
    }
    
    public func setExposureMode(_ v: AVCaptureDevice.ExposureMode) {
        cameraManager.setExposureMode(v)
    }
    
    public func setExposure(iso: Float?, duration: Double?) {
        cameraManager.setExposure(iso: iso, duration: duration)
    }
    
    public func setZoomFactor(_ newValue: CGFloat, adjust: Bool, withRate: Float, completion: (() -> Void)?) {
        cameraManager.setZoomFactor(newValue, adjust: adjust, withRate: withRate, completion: completion)
    }
    
    public func setDepth(_ v: Bool) {
        cameraManager.setDepth(v)
    }
    
    public func setPortrait(_ v: Bool) {
        cameraManager.setPortrait(v)
    }
    
    public func setQuality(_ v: AVCapturePhotoOutput.QualityPrioritization) {
        cameraManager.setQuality(v)
    }
    
    public func setFocusMode(_ v: AVCaptureDevice.FocusMode) {
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
