//
//  CameraBluetoothClient.swift
//  tCamera
//
//  Created by Thinh Nguyen on 8/19/24.
//

import Foundation
import SwiftUI
import Combine
import CoreBluetooth
import AVFoundation
import CoreImage
import TnIosBase

public class TnCameraProxyClient: NSObject, ObservableObject, TnLoggable {
    @Published public private(set) var currentCiImage: CIImage?
    @Published public private(set) var albums: [String] = []
    public var delegate: TnCameraDelegate? = nil

    private let ble: TnBluetoothClient
    private var networkCommon: TnNetworkConnection?
    private var networkStreaming: TnNetworkConnection?

    private let transportingInfo: TnNetworkTransportingInfo
    private var settings: TnCameraSettings? = nil
    private var status: TnCameraStatus = .none
    
    private let videoDecoder: TnTranscodingDecoderComposite = .init(config: .default)
    
    public init(bleInfo: TnNetworkBleInfo, transportingInfo: TnNetworkTransportingInfo) {
        self.transportingInfo = transportingInfo
        self.ble = .init(info: bleInfo, transportingInfo: transportingInfo)
        super.init()
        
        self.listenEncoding()
        
        logDebug("inited")
    }
    
    public var bleDelegate: TnBluetoothClientDelegate? {
        get {
            ble.delegate
        }
        set {
            ble.delegate = newValue
        }
    }
}

// MARK: encoding
extension TnCameraProxyClient {
    private func listenEncoding() {
        logDebug("listen decoded image ...")
        videoDecoder.listen{ [self] ciImage in
            currentCiImage = ciImage
        }
    }
    
    private func listenStreaming() {
        guard let stream = networkStreaming?.receiveStream.stream else { return }
        send(msgType: .invalidateVideoEncoder)

        Task {
            logDebug("listen packet stream ...")
            
            for await packet in stream {
                do {
                    logDebug("decode packet ...", packet.count)
//                    try await self.videoDecoder.decode(packet: packet)
                } catch {
                    logError("decode packet error", error)
//                    self.send(msgType: .invalidateVideoEncoder)
                }
            }
            
            logDebug("listen packet stream !")
        }
    }
}

// MARK: solve messages
extension TnCameraProxyClient {
    func solveMsg(data: Data) {
        let msgData = TnMessageData(data: data)
        guard let messageType = msgData.cameraMsgType else { return }

        switch messageType {
        case .getSettingsResponse:
            solveMsgValue(msgData: msgData) { (v: TnCameraSettingsValue) in
                if let settings = v.settings {
                    self.settings = settings
                    delegate?.tnCamera(self, settings: settings)
                }

                if let status = v.status, self.status != status {
                    self.status = status
                    delegate?.tnCamera(self, status: status)
                }

                if networkCommon == nil, let hostInfo = v.network {
                    networkCommon = .init(hostInfo: hostInfo, name: "common", delegate: self, transportingInfo: transportingInfo)
                    networkCommon!.start()
                    
                    networkStreaming = .init(hostInfo: hostInfo, name: "streaming", delegate: self, transportingInfo: transportingInfo)
                    networkStreaming!.start()
                }
            }
            
        case .getAlbumsResponse:
            solveMsgValue(msgData: msgData) { (v: [String]) in
                self.albums = v
            }
        default:
            return
        }
    }
}

// MARK: TnCameraProtocol
extension TnCameraProxyClient: TnCameraProtocol {
    public var currentCiImagePublisher: Published<CIImage?>.Publisher {
        $currentCiImage
    }
    
    public func setup() {
        ble.setupBle()
    }

    public func startCapturing() {
        send(msgType: .startCapturing)
    }
    
    public func stopCapturing() {
        send(msgType: .stopCapturing)
    }
    
    public func toggleCapturing() {
        send(msgType: .toggleCapturing)
    }
    
    public func switchCamera() {
        send(msgType: .switchCamera)
    }
    
    public func captureImage() {
        send(msgType: .captureImage)
    }
    
    public func setLivephoto(_ v: Bool) {
        send(msgType: .setLivephoto, value: v)
    }
    
    public func setFlash(_ v: AVCaptureDevice.FlashMode) {
        send(msgType: .setFlash, value: v)
    }
    
    public func setHDR(_ v: TnTripleState) {
        send(msgType: .setHDR, value: v)
    }
    
    public func setPreset(_ v: AVCaptureSession.Preset) {
        send(msgType: .setPreset, value: v)
    }
    
    public func setCameraType(_ v: AVCaptureDevice.DeviceType) {
        send(msgType: .setCameraType, value: v)
    }
    
    public func setWideColor(_ v: Bool) {
        send(msgType: .setWideColor, value: v)
    }
    
    public func setExposureMode(_ v: AVCaptureDevice.ExposureMode) {
        send(msgType: .setExposureMode, value: v)
    }
    
    public func setExposure(_ v: TnCameraExposureValue) {
    }
    
    public func setZoomFactor(_ v: TnCameraZoomFactorValue) {
        send(msgType: .setZoomFactor, value: v)
    }
    
    public func setDepth(_ v: Bool) {
        send(msgType: .setDepth, value: v)
    }
    
    public func setPortrait(_ v: Bool) {
        send(msgType: .setPortrait, value: v)
    }
    
    public func setPriority(_ v: AVCapturePhotoOutput.QualityPrioritization) {
        send(msgType: .setQuality, value: v)
    }
    
    public func setFocusMode(_ v: AVCaptureDevice.FocusMode) {
        send(msgType: .setFocusMode, value: v)
    }
    
    public func setTransporting(_ v: TnCameraTransportingValue) {
        send(msgType: .setTransporting, value: v)
    }
    
    public func setCapturing(_ v: TnCameraCapturingValue) {
        send(msgType: .setCapturing, value: v)
    }
    
    public func createAlbum(_ v: String) {
        send(msgType: .createAlbum, value: v)
    }
}

// MARK: transportable
extension TnCameraProxyClient {
    var encoder: TnEncoder {
        ble.encoder
    }
    
    var decoder: TnDecoder {
        ble.decoder
    }
    
    func send(data: Data) {
        if networkCommon == nil {
            ble.send(data: data)
        } else {
            Task {
                try await networkCommon?.send(data: data)
            }
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

// MARK: TnBluetoothClientDelegate
extension TnCameraProxyClient: TnBluetoothClientDelegate {
    public func tnBluetoothClient(ble: TnBluetoothClient, statusChanged: TnBluetoothClient.Status) {
    }
    
    public func tnBluetoothClient(ble: TnBluetoothClient, discoveredID: String) {
        ble.connect(peripheralID: discoveredID)
    }
    
    public func tnBluetoothClient(ble: TnBluetoothClient, connectedID: String) {
        send(msgType: .getSettings)
    }
    
    public func tnBluetoothClient(ble: TnBluetoothClient, disconnectedID: String) {
    }
    
    public func tnBluetoothClient(ble: TnBluetoothClient, sentID: String, sentData: Data) {
    }
    
    public func tnBluetoothClient(ble: TnBluetoothClient, receivedID: String, receivedData: Data) {
        solveMsg(data: receivedData)
    }
}

// MARK: TnNetworkDelegate
extension TnCameraProxyClient: TnNetworkDelegate {
    public func tnNetworkReady(_ connection: TnNetworkConnection) {
        switch connection.name {
        case "common":
            listenCommon()
        case "streaming":
            listenStreaming()
        default:
            break
        }
    }
    
    public func tnNetworkStop(_ connection: TnNetworkConnection, error: (any Error)?) {
        networkCommon = nil
        networkStreaming = nil
    }
}

// MARK: receive msg
extension TnCameraProxyClient {
    private func listenCommon() {
        guard let stream = networkCommon?.receiveStream.stream else { return }
        Task {
            for await data in stream {
                self.solveMsg(data: data)
            }
        }
    }
}
