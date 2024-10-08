//
//  TnCameraProxyServerNew.swift
//  TnCameraBase
//
//  Created by Thinh Nguyen on 9/19/24.
//

import Foundation
import SwiftUI
import Combine
import AVFoundation
import CoreImage
import TnIosBase

public class TnCameraProxyServerAsync: TnLoggable {
    private let cameraService: TnCameraService
    private let network: TnNetworkServer
    private let ble: TnBluetoothServer
    @Published public private(set) var albums: [String] = []

    public var delegate: TnCameraDelegate? = nil

    public init(_ cameraService: TnCameraService, bleInfo: TnNetworkBleInfo, transportingInfo: TnNetworkTransportingInfo) {
        self.cameraService = cameraService
        self.ble = .init(bleInfo: bleInfo, transportingInfo: transportingInfo)
        guard let address = TnNetworkHelper.getAddressList(for: [.wifi, .cellularBridge, .cellular]).first else {
            fatalError("Cannot start without network")
        }
        
        self.network = .init(hostInfo: .init(host: address.address, port: 1234), delegate: nil, transportingInfo: transportingInfo)

        Task {
            self.albums = await cameraService.library.getAlbums()
            
            await cameraService.$isSettingsChanging.onReceive { v in
                if !v {
                    Task {
                        self.logDebug("settings changed", "zoom: ", await cameraService.settings.zoomFactor)
                        self.delegate?.tnCamera(settings: await cameraService.settings)
                    }
                }
            }

            await cameraService.$status.onReceive { v in
                self.logDebug("status changed", v)
                self.delegate?.tnCamera(status: v)
            }
        }
        
        self.network.delegate = self
        self.network.start()

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
}

// MARK: solve messages
extension TnCameraProxyServerAsync {
    private func solveData(data: Data) {
        let receivedMsg = TnMessage(data: data)
        guard let messageType: TnCameraMessageType = .init(rawValue: receivedMsg.typeCode) else { return }
        logDebug("receive", messageType)

        switch messageType {
        case .toggleCapturing:
            toggleCapturing()

        case .startCapturing:
            startCapturing()

        case .stopCapturing:
            stopCapturing()

        case .switchCamera:
            switchCamera()
            
        case .captureImage:
            captureImage()

        case .getSettings:
            // response settings
            Task {
                send(.getSettingsResponse,
                     TnCameraSettingsValue(settings: await cameraService.settings, status: await cameraService.status, network: network.hostInfo),
                     useBle: true
                )
            }

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
                setPriority(v)
            }
            
        case .setFocusMode:
            solveMsgValue(receivedMsg) { (v: AVCaptureDevice.FocusMode) in
                setFocusMode(v)
            }

        case .setTransporting:
            solveMsgValue(receivedMsg) { (v: TnCameraTransportingValue) in
                setTransporting(v)
            }
            
        case .getAlbums:
            send(.getAlbumsResponse, albums)
        default:
            return
        }
    }
}

// MARK: TnBluetoothServerDelegate
extension TnCameraProxyServerAsync: TnBluetoothServerDelegate {
    public func tnBluetoothServer(ble: TnBluetoothServer, statusChanged: TnBluetoothServer.Status) {
        switch statusChanged {
        case .inited:
            ble.start()
        case .started:
            Task {
                try? await cameraService.startCapturing()
            }
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


// MARK: TnCameraProxyProtocol
extension TnCameraProxyServerAsync: TnCameraProxyProtocol {
    public var decoder: TnDecoder {
        ble.decoder
    }

    public func send(_ object: TnCameraMessageProtocol, useBle: Bool = false) {
        Task {
            if useBle {
                try? await ble.send(object: object)
            } else {
                try? await network.send(object: object)
            }
        }
    }
    
    public func sendImage() {
        Task {
            if let currentImageData = await cameraService.currentImageData {
                send(.getImageResponse, currentImageData)
            }
        }
    }
    
    public func setup() {
        ble.setupBle()
    }
    
    public var currentCiImagePublisher: Published<CIImage?>.Publisher {
        get async {
            await cameraService.$currentCiImage
        }
    }
    
    public func startCapturing() {
        Task {
            try await cameraService.startCapturing()
        }
    }
    
    public func stopCapturing() {
        Task {
            await cameraService.stopCapturing()
        }
    }
    
    public func toggleCapturing() {
        Task {
            try? await cameraService.toggleCapturing()
        }
    }
    
    public func switchCamera() {
        Task {
            try? await cameraService.switchCamera()
        }
    }
    
    // MARK: captureImage
    public func captureImage() {
        Task {
            if let output = try? await cameraService.captureImage() {
                delegate?.tnCamera(captured: output)
            }
        }
    }
    
    public func setLivephoto(_ v: Bool) {
        Task {
            try? await cameraService.setLivephoto(v)
        }
    }
    
    public func setFlash(_ v: AVCaptureDevice.FlashMode) {
        Task {
            await cameraService.setFlash(v)
        }
    }
    
    public func setHDR(_ v: TnTripleState) {
        Task {
            try? await cameraService.setHDR(v)
        }
    }
    
    public func setPreset(_ v: AVCaptureSession.Preset) {
        Task {
            try? await cameraService.setPreset(v)
        }
    }
    
    public func setCameraType(_ v: AVCaptureDevice.DeviceType) {
        Task {
            try? await cameraService.setCameraType(v)
        }
    }
    
    public func setWideColor(_ v: Bool) {
        Task {
            try? await cameraService.setWideColor(v)
        }
    }
    
    public func setExposure(_ v: TnCameraExposureValue) {
        Task {
            try? await cameraService.setExposure(v)
        }
    }
    
    public func setZoomFactor(_ v: TnCameraZoomFactorValue) {
        Task {
            try? await cameraService.setZoomFactor(v)
        }
    }
    
    public func setDepth(_ v: Bool) {
        Task {
            try? await cameraService.setDepth(v)
        }
    }
    
    public func setPortrait(_ v: Bool) {
        Task {
            try? await cameraService.setPortrait(v)
        }
    }
    
    public func setPriority(_ v: AVCapturePhotoOutput.QualityPrioritization) {
        Task {
            try? await cameraService.setPriority(v)
        }
    }
    
    public func setFocusMode(_ v: AVCaptureDevice.FocusMode) {
        Task {
            try? await cameraService.setFocusMode(v)
        }
    }
    
    public func setTransporting(_ v: TnCameraTransportingValue) {
        Task {
            await cameraService.setTransporting(v)
        }
    }
    
    public func setCapturing(_ v: TnCameraCapturingValue) {
        Task {
            await cameraService.setCapturing(v)
        }
    }

    public func createAlbum(_ v: String) {
        Task {
            try await cameraService.library.getOrCreateAlbum(name: v)
            albums = await cameraService.library.getAlbums()
            send(.getAlbumsResponse, albums)
        }
    }

}

// MARK: TnNetworkDelegateServer
extension TnCameraProxyServerAsync: TnNetworkDelegateServer {
    public func tnNetworkReady(_ server: TnNetworkServer) {
    }
    
    public func tnNetworkStop(_ server: TnNetworkServer, error: (any Error)?) {
    }

    public func tnNetworkStop(_ server: TnNetworkServer, connection: TnNetworkConnectionServer, error: (any Error)?) {
    }

    public func tnNetworkAccepted(_ server: TnNetworkServer, connection: TnNetworkConnectionServer) {
    }
    
    public func tnNetworkReceived(_ server: TnNetworkServer, connection: TnNetworkConnection) {
        connection.processMsgQueue { msgData in
            self.solveData(data: msgData)
        }
    }
    
    public func tnNetworkSent(_ server: TnNetworkServer, connection: TnNetworkConnection) {
    }
}
