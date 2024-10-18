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

@available(iOS 17.0, *)
public class TnCameraProxyServer: TnLoggable {
    private let cameraService: TnCameraService
    private let network: TnNetworkServer
    private let ble: TnBluetoothServer
    
    private var status: TnCameraStatus = .none
    private var settings: TnCameraSettings? = nil
    
    public private(set) var albums: [String] = []

    public var delegate: TnCameraDelegate? = nil
    private let videoEncoder = TnTranscodingEncoderComposite()

    public init(_ cameraService: TnCameraService, bleInfo: TnNetworkBleInfo, transportingInfo: TnNetworkTransportingInfo) {
        self.cameraService = cameraService
        self.ble = .init(bleInfo: bleInfo, transportingInfo: transportingInfo)
        guard let address = TnNetworkHelper.getAddressList(for: [.wifi, .cellularBridge, .cellular]).first else {
            fatalError("Cannot start without network")
        }
        
        self.network = .init(hostInfo: .init(host: address.address, port: 1234), delegate: nil, transportingInfo: transportingInfo)
        self.network.delegate = self
        self.network.start()
                
        self.listenService()
        self.listenEncoding()

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

// MARK: listen service
@available(iOS 17.0, *)
extension TnCameraProxyServer {
    private func listenService() {
        Task {
            self.albums = await cameraService.library.getAlbums()
            
            await cameraService.$isSettingsChanging.onReceive { [self] v in
                Task {
                    if status == .started && !v {
                        logDebug("settings changed")
                        self.settings = await cameraService.settings
                        delegate?.tnCamera(self, settings: self.settings!)
                    }
                }
            }

            await cameraService.$status.onReceive { [self] v in
                if self.status != v {
                    logDebug("status changed", v)
                    self.status = v
                    delegate?.tnCamera(self, status: v)
                }
            }
        }
        
    }
}

// MARK: encoding
@available(iOS 17.0, *)
extension TnCameraProxyServer {
    private var canEncoding: Bool {
        status == .started && network.hasConnection(name: "streaming")
    }
    
    private func listenEncoding() {
        Task {
            try self.videoEncoder.listen(packetHandler: { packet in
                if self.canEncoding {
                    try await self.send(data: packet, to: ["streaming"])
                }
            })
        }

        Task {
            while true {
                if canEncoding, let ciImage = await cameraService.currentCiImage {
                    do {
                        try await videoEncoder.encode(ciImage)
                    } catch TnTranscodingError.invalidSession {
                        videoEncoder.invalidate()
                    }
                }
                try await Task.sleep(nanoseconds: 30_000_000)
            }
        }
    }
}

// MARK: solve messages
@available(iOS 17.0, *)
extension TnCameraProxyServer {
    private func solveData(data: Data) {
        let msgData = TnMessageData(data: data)
        guard let messageType = msgData.cameraMsgType else { return }

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
            send(msgType: .getSettingsResponse,
                 value: TnCameraSettingsValue(settings: settings, status: status, network: network.hostInfo),
                 to: ["common"]
            )

//        case .getImage:
//            sendImage()
            
        case .setZoomFactor:
            solveMsgValue(msgData: msgData) { (v: TnCameraZoomFactorValue) in
                setZoomFactor(v)
            }

        case .setLivephoto:
            solveMsgValue(msgData: msgData) { (v: Bool) in
                setLivephoto(v)
            }
            
        case .setFlash:
            solveMsgValue(msgData: msgData) { (v: AVCaptureDevice.FlashMode) in
                setFlash(v)
            }

        case .setHDR:
            solveMsgValue(msgData: msgData) { (v: TnTripleState) in
                setHDR(v)
            }

        case .setPreset:
            solveMsgValue(msgData: msgData) { (v: AVCaptureSession.Preset) in
                setPreset(v)
            }
            
        case .setCameraType:
            solveMsgValue(msgData: msgData) { (v: AVCaptureDevice.DeviceType) in
                setCameraType(v)
            }
            
        case .setQuality:
            solveMsgValue(msgData: msgData) { (v: AVCapturePhotoOutput.QualityPrioritization) in
                setPriority(v)
            }
            
        case .setFocusMode:
            solveMsgValue(msgData: msgData) { (v: AVCaptureDevice.FocusMode) in
                setFocusMode(v)
            }

        case .setTransporting:
            solveMsgValue(msgData: msgData) { (v: TnCameraTransportingValue) in
                setTransporting(v)
            }
            
        case .getAlbums:
            send(msgType: .getAlbumsResponse, value: albums, to: ["common"])
        default:
            return
        }
    }
}

// MARK: TnBluetoothServerDelegate
@available(iOS 17.0, *)
extension TnCameraProxyServer: TnBluetoothServerDelegate {
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
@available(iOS 17.0, *)
extension TnCameraProxyServer: TnCameraProxyProtocol {
    public var decoder: TnDecoder {
        ble.decoder
    }
    
    public var encoder: TnEncoder {
        ble.encoder
    }
    
    public func send(data: Data, to: [String]?) async throws {
        if network.hasConnections {
            Task {
                try? await network.send(data: data, to: to)
            }
        } else if data.count < 2000 {
            ble.send(data: data, to: to)
        }
    }
    
//    public func sendImage() {
////        Task {
////            if let currentImageData = await cameraService.currentImageData {
////                network.send(msgType: .getImageResponse, value: currentImageData, to: ["image"])
////            }
////        }
//    }

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
                delegate?.tnCamera(self, captured: output)
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
            send(msgType: .getAlbumsResponse, value: albums, to: ["common"])
        }
    }

}

// MARK: TnNetworkDelegateServer
@available(iOS 17.0, *)
extension TnCameraProxyServer: TnNetworkDelegateServer {
    public func tnNetworkReady(_ server: TnNetworkServer) {
    }
    
    public func tnNetworkStop(_ server: TnNetworkServer, error: Error?) {
    }

    public func tnNetworkStop(_ server: TnNetworkServer, connection: TnNetworkConnection, error: Error?) {
    }

    public func tnNetworkAccepted(_ server: TnNetworkServer, connection: TnNetworkConnection) {
        if connection.name == "streaming" {
            videoEncoder.invalidate()
        }
    }
    
    public func tnNetworkReceived(_ server: TnNetworkServer, connection: TnNetworkConnection, data: Data) {
        self.solveData(data: data)
    }

    public func tnNetworkSent(_ server: TnNetworkServer, connection: TnNetworkConnection, count: Int) {
    }
}
