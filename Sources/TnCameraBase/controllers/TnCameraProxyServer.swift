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
    private let videoEncoder: TnTranscodingEncoderComposite = TnTranscodingEncoderComposite()

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
            
            await cameraService.listen(
                statusHandler: { [self] status in
                    logDebug("status changed", status)
                    self.status = status
                    
                    // send status
                    self.send(msgType: .getSettingsResponse, value: TnCameraSettingsValue(settings: nil, status: status, network: nil))

                    delegate?.tnCamera(self, status: status)
                },
                settingsHandler: { [self] settings in
                    logDebug("settings changed")
                    self.settings = settings
                    
                    // send settings
                    self.send(msgType: .getSettingsResponse, value: TnCameraSettingsValue(settings: settings, status: nil, network: nil))

                    delegate?.tnCamera(self, settings: settings)
                }
            )
        }
    }
}

// MARK: encoding
@available(iOS 17.0, *)
extension TnCameraProxyServer {
    private var canEncoding: Bool {
        status == .started
    }
    
    private func listenEncoding() {
        // listen encoding packet
        videoEncoder.listen(packetHandler: { [self] packet in
            if canEncoding {
                try await tnDoCatchAsync(name: "send encoded packet") { [self] in
                    try? await network.send(data: packet, to: ["streaming"])
                }
            }
        })

        // listen image to encoding, passive just encode, async
        Task {
            try await cameraService.listenImage { [self] ciImage in
                if canEncoding {
                    try await tnDoCatchAsync(name: "encode image") { [self] in
                        try? await videoEncoder.encode(ciImage)
                    }
                }
            }
        }
    }
}

// MARK: listen data
@available(iOS 17.0, *)
extension TnCameraProxyServer {
    private func listenCommon(connection: TnNetworkConnection) {
        Task {
            for await data in connection.receiveStream.stream {
                solveData(data: data)
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
                 value: TnCameraSettingsValue(settings: settings, status: status, network: network.hostInfo)
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
            send(msgType: .getAlbumsResponse, value: albums)
            
        case .invalidateVideoEncoder:
            videoEncoder.invalidate()
            
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
                try await cameraService.startCapturing()
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

// MARK: transportable
@available(iOS 17.0, *)
extension TnCameraProxyServer {
    var decoder: TnDecoder {
        ble.decoder
    }
    
    var encoder: TnEncoder {
        ble.encoder
    }
    
    func send(data: Data) {
        if network.hasConnection(name: "common") {
            Task {
                try await network.send(data: data, to: ["common"])
            }
        } else if data.count < 2000 {
            ble.send(data: data)
        }
    }
    
    func send(msgType: TnCameraMessageType) {
        self.send(data: msgType.rawValue.toData())
    }

    func send<TMessageValue: Codable>(msgType: TnCameraMessageType, value: TMessageValue) {
        if let data = try? TnMessageValue.from(msgType, value).toData(encoder: encoder) {
            self.send(data: data)
        }
    }
    
    func solveMsgValue<TMessageValue: Codable>(msgData: TnMessageData, handler: (TMessageValue) -> Void) {
        if let msg: TnMessageValue<TMessageValue> = msgData.toObject(decoder: decoder) {
            handler(msg.value)
        }
    }
}

// MARK: TnCameraProxyProtocol
@available(iOS 17.0, *)
extension TnCameraProxyServer: TnCameraProtocol {
    public func setup() {
        ble.setupBle()
    }
    
    public var currentCiImagePublisher: Published<CIImage?>.Publisher {
        get async {
            await cameraService.currentCiImagePublisher
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
            try await cameraService.toggleCapturing()
        }
    }
    
    public func switchCamera() {
        Task {
            try await cameraService.switchCamera()
        }
    }
    
    // MARK: captureImage
    public func captureImage() {
        Task {
            let output = try await cameraService.captureImage()
            delegate?.tnCamera(self, captured: output)
        }
    }
    
    public func setLivephoto(_ v: Bool) {
        Task {
            try await cameraService.setLivephoto(v)
        }
    }
    
    public func setFlash(_ v: AVCaptureDevice.FlashMode) {
        Task {
            await cameraService.setFlash(v)
        }
    }
    
    public func setHDR(_ v: TnTripleState) {
        Task {
            try await cameraService.setHDR(v)
        }
    }
    
    public func setPreset(_ v: AVCaptureSession.Preset) {
        Task {
            try await cameraService.setPreset(v)
            videoEncoder.invalidate()
        }
    }
    
    public func setCameraType(_ v: AVCaptureDevice.DeviceType) {
        Task {
            try await cameraService.setCameraType(v)
        }
    }
    
    public func setWideColor(_ v: Bool) {
        Task {
            try await cameraService.setWideColor(v)
        }
    }
    
    public func setExposure(_ v: TnCameraExposureValue) {
        Task {
            try await cameraService.setExposure(v)
        }
    }
    
    public func setZoomFactor(_ v: TnCameraZoomFactorValue) {
        Task {
            try await cameraService.setZoomFactor(v)
        }
    }
    
    public func setDepth(_ v: Bool) {
        Task {
            try await cameraService.setDepth(v)
        }
    }
    
    public func setPortrait(_ v: Bool) {
        Task {
            try await cameraService.setPortrait(v)
        }
    }
    
    public func setPriority(_ v: AVCapturePhotoOutput.QualityPrioritization) {
        Task {
            try await cameraService.setPriority(v)
        }
    }
    
    public func setFocusMode(_ v: AVCaptureDevice.FocusMode) {
        Task {
            try await cameraService.setFocusMode(v)
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
            send(msgType: .getAlbumsResponse, value: albums)
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

    public func tnNetworkDisconnected(_ server: TnNetworkServer, connection: TnNetworkConnection, error: Error?) {
    }

    public func tnNetworkAccepted(_ server: TnNetworkServer, connection: TnNetworkConnection) {
        if connection.name == "common" {
            listenCommon(connection: connection)
        }
    }
}
