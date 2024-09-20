////
////  CameraBluetoothServer.swift
////  tCamera
////
////  Created by Thinh Nguyen on 8/19/24.
////
//
//import Foundation
//import SwiftUI
//import Combine
//import AVFoundation
//import CoreImage
//import TnIosBase
//
//public class TnCameraProxyServer: TnLoggable {
//    public let LOG_NAME = "TnCameraProxyServer"
//
//    private let cameraService: TnCameraLocal
//    private var network: TnNetworkServer?
//    private let ble: TnBluetoothServer
//
//    public init(_ cameraService: TnCameraLocal, networkInfo: TnNetworkServiceInfo) {
//        self.cameraService = cameraService
//        ble = .init(info: networkInfo)
//        if let address = TnNetworkHelper.getAddressList(for: [.wifi, .cellularBridge, .cellular]).first {
//            network = .init(host: address.address, port: 1234, queue: .main, delegate: self, EOM: networkInfo.EOM, MTU: networkInfo.MTU)
//            network?.start()
//        }
//        
//        logDebug("inited")
//    }
//    
//    public var bleDelegate: TnBluetoothServerDelegate? {
//        get {
//            ble.delegate
//        }
//        set {
//            ble.delegate = newValue
//        }
//    }
//    
//    public var captureCompletion: ((UIImage) -> Void)? {
//        get {
//            cameraService.captureCompletion
//        }
//        set {
//            cameraService.captureCompletion = newValue
//        }
//    }
//
//}
//
//// MARK: TnBluetoothServerDelegate
//extension TnCameraProxyServer: TnBluetoothServerDelegate {
//    public func tnBluetoothServer(ble: TnBluetoothServer, statusChanged: TnBluetoothServer.Status) {
//        switch statusChanged {
//        case .inited:
//            ble.start()
//        case .started:
//            cameraService.startCapturing()
//        default:
//            return
//        }
//    }
//    
//    public func tnBluetoothServer(ble: TnBluetoothServer, sentIDs: [String], sentData: Data) {
//    }
//
//    public func tnBluetoothServer(ble: TnBluetoothServer, receivedID: String, receivedData: Data) {
//        solveData(data: receivedData)
//    }
//}
//
//extension TnCameraProxyServer {
//    public func send(_ object: TnCameraMessageProtocol, useBle: Bool = false) {
//        if useBle {
//            try? ble.send(object: object)
//        } else {
//            try? network?.send(object: object)
//        }
//    }
//    
//    public func sendImage() {
//        if let currentCiImage = cameraService.currentCiImage {
//            send(.getImageResponse, currentCiImage.jpegData(scale: settings.transportScale, compressionQuality: settings.transportCompressQuality))
//        }
//    }
//    
//    func solveData(data: Data) {
//        let receivedMsg = TnMessage(data: data)
//        let messageType: TnCameraMessageType = .init(rawValue: receivedMsg.typeCode)!
//        logDebug("receive", messageType)
//
//        switch messageType {
//        case .toggleCapturing:
//            toggleCapturing()
//
//        case .switchCamera:
//            switchCamera()
//            
//        case .captureImage:
//            captureImage()
//
//        case .getSettings:
//            // response settings
//            send(.getSettingsResponse, TnCameraSettingsValue(settings: cameraService.settings, status: cameraService.status, network: network), useBle: true)
//
//        case .getImage:
//            sendImage()
//            
//        case .setZoomFactor:
//            solveMsgValue(receivedMsg) { (v: TnCameraZoomFactorValue) in
//                setZoomFactor(v)
//            }
//
//        case .setLivephoto:
//            solveMsgValue(receivedMsg) { (v: Bool) in
//                setLivephoto(v)
//            }
//            
//        case .setFlash:
//            solveMsgValue(receivedMsg) { (v: AVCaptureDevice.FlashMode) in
//                setFlash(v)
//            }
//
//        case .setHDR:
//            solveMsgValue(receivedMsg) { (v: TnTripleState) in
//                setHDR(v)
//            }
//
//        case .setPreset:
//            solveMsgValue(receivedMsg) { (v: AVCaptureSession.Preset) in
//                setPreset(v)
//            }
//            
//        case .setCameraType:
//            solveMsgValue(receivedMsg) { (v: AVCaptureDevice.DeviceType) in
//                setCameraType(v)
//            }
//            
//        case .setQuality:
//            solveMsgValue(receivedMsg) { (v: AVCapturePhotoOutput.QualityPrioritization) in
//                setPriority(v)
//            }
//            
//        case .setFocusMode:
//            solveMsgValue(receivedMsg) { (v: AVCaptureDevice.FocusMode) in
//                setFocusMode(v)
//            }
//
//        case .setTransport:
//            solveMsgValue(receivedMsg) { (v: TnCameraTransportValue) in
//                setTransport(v)
//            }
//        default:
//            return
//        }
//    }
//}
//
//// MARK: CameraManagerProtocol
//extension TnCameraProxyServer: TnCameraProxyProtocol {
//    public func setup() {
//        ble.setupBle()
//    }
//    
//    public var currentCiImagePublisher: Published<CIImage?>.Publisher {
//        cameraService.$currentCiImage
//    }
//    
//    public var settingsPublisher: Published<TnCameraSettings>.Publisher {
//        cameraService.$settings
//    }
//    
//    public var settings: TnCameraSettings {
//        cameraService.settings
//    }
//    
//    public var statusPublisher: Published<TnCameraStatus>.Publisher {
//        cameraService.$status
//    }
//    
//    public var status: TnCameraStatus {
//        cameraService.status
//    }
//
//    public func startCapturing() {
//        cameraService.startCapturing()
//    }
//    
//    public func stopCapturing() {
//        cameraService.stopCapturing()
//    }
//
//    public func toggleCapturing() {
//        cameraService.toggleCapturing()
//    }
//    
//    public func switchCamera() {
//        cameraService.switchCamera()
//    }
//    
//    public func captureImage() {
//        cameraService.captureImage()
//    }
//    
//    public func setLivephoto(_ v: Bool) {
//        cameraService.setLivephoto(v)
//    }
//    
//    public func setFlash(_ v: AVCaptureDevice.FlashMode) {
//        cameraService.setFlash(v)
//    }
//    
//    public func setHDR(_ v: TnTripleState) {
//        cameraService.setHDR(v)
//    }
//    
//    public func setPreset(_ v: AVCaptureSession.Preset) {
//        cameraService.setPreset(v)
//    }
//    
//    public func setCameraType(_ v: AVCaptureDevice.DeviceType) {
//        cameraService.setCameraType(v)
//    }
//    
//    public func setExposureMode(_ v: AVCaptureDevice.ExposureMode) {
//        cameraService.setExposureMode(v)
//    }
//    
//    public func setExposure(_ v: TnCameraExposureValue) {
//        cameraService.setExposure(v)
//    }
//    
//    public func setZoomFactor(_ v: TnCameraZoomFactorValue) {
//        cameraService.setZoomFactor(v)
//    }
//    
//    public func setDepth(_ v: Bool) {
//        cameraService.setDepth(v)
//    }
//    
//    public func setPortrait(_ v: Bool) {
//        cameraService.setPortrait(v)
//    }
//    
//    public func setPriority(_ v: AVCapturePhotoOutput.QualityPrioritization) {
//        cameraService.setQuality(v)
//    }
//    
//    public func setFocusMode(_ v: AVCaptureDevice.FocusMode) {
//    }
//    
//    public func setTransport(_ v: TnCameraTransportValue) {
//        cameraService.setTransport(v)
//    }
//}
//
//extension TnCameraProxyServer: TnNetworkDelegateServer {
//    public func tnNetworkReady(_ server: TnNetworkServer) {
//    }
//    
//    public func tnNetworkStop(_ server: TnNetworkServer, error: (any Error)?) {
//        network = nil
//    }
//    
//    public func tnNetwork(_ server: TnNetworkServer, accepted: TnNetworkConnectionServer) {
//    }
//    
//    public func tnNetwork(_ server: TnNetworkServer, stopped: TnNetworkConnectionServer, error: (any Error)?) {
//    }
//    
//    public func tnNetwork(_ server: TnNetworkServer, connection: TnNetworkConnection, receivedData: Data) {
//        self.solveData(data: receivedData)
//    }
//    
//    public func tnNetwork(_ server: TnNetworkServer, connection: TnNetworkConnection, sentData: Data) {
//    }
//}
