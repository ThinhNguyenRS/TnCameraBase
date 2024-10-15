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
    private var networkImage: TnNetworkConnection?

    private let transportingInfo: TnNetworkTransportingInfo
    private var settings: TnCameraSettings? = nil
    private var status: TnCameraStatus = .none
    
    public init(bleInfo: TnNetworkBleInfo, transportingInfo: TnNetworkTransportingInfo) {
        self.transportingInfo = transportingInfo
        self.ble = .init(info: bleInfo, transportingInfo: transportingInfo)
        super.init()
        
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

// MARK: solve messages
extension TnCameraProxyClient {
    func solveData(data: Data) {
        let msgData = TnMessageData(data: data)
        guard let messageType = msgData.cameraMsgType else { return }
        logDebug("receive", messageType)

        switch messageType {
        case .getSettingsResponse:
            solveMsgValue(msgData: msgData) { (v: TnCameraSettingsValue) in
                if let settings = v.settings {
                    self.settings = settings
                    delegate?.tnCamera(settings: settings)
                }

                if let status = v.status, self.status != status {
                    self.status = status
                    delegate?.tnCamera(status: status)
                }

                if status == .started && networkImage != nil {
                    networkImage?.send(msgType: .getImage, to: nil)
                }

                if networkCommon == nil, let hostInfo = v.network {
                    networkCommon = .init(hostInfo: hostInfo, name: "common", delegate: self, transportingInfo: transportingInfo)
                    networkCommon!.start()
                    
                    networkImage = .init(hostInfo: hostInfo, name: "image", delegate: self, transportingInfo: transportingInfo)
                    networkImage!.start()
                }
            }
            
        case .getImageResponse:
            solveMsgValue(msgData: msgData) { (v: Data) in
                let uiImage: UIImage = .init(data: v)!
                logDebug("image", uiImage.size.width, uiImage.size.height, uiImage.scale)

                let ciImage = CIImage(image: uiImage)!
                self.currentCiImage = ciImage
                
                if status == .started && networkImage != nil && (settings?.transporting.continuous ?? false) {
                    networkImage?.send(msgType: .getImage, to: nil)
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

// MARK: CameraManagerProxyProtocol
extension TnCameraProxyClient: TnCameraProtocol {
    public var currentCiImagePublisher: Published<CIImage?>.Publisher {
        $currentCiImage
    }
    
    public func startCapturing() {
        send(msgType: .startCapturing, to: nil)
    }
    
    public func stopCapturing() {
        send(msgType: .stopCapturing, to: nil)
    }
    
    public func toggleCapturing() {
        send(msgType: .toggleCapturing, to: nil)
    }
    
    public func switchCamera() {
        send(msgType: .switchCamera, to: nil)
    }
    
    public func captureImage() {
        send(msgType: .captureImage, to: nil)
    }
    
    public func setLivephoto(_ v: Bool) {
        send(msgType: .setLivephoto, value: v, to: nil)
    }
    
    public func setFlash(_ v: AVCaptureDevice.FlashMode) {
        send(msgType: .setFlash, value: v, to: nil)
    }
    
    public func setHDR(_ v: TnTripleState) {
        send(msgType: .setHDR, value: v, to: nil)
    }
    
    public func setPreset(_ v: AVCaptureSession.Preset) {
        send(msgType: .setPreset, value: v, to: nil)
    }
    
    public func setCameraType(_ v: AVCaptureDevice.DeviceType) {
        send(msgType: .setCameraType, value: v, to: nil)
    }
    
    public func setWideColor(_ v: Bool) {
        send(msgType: .setWideColor, value: v, to: nil)
    }
    
    public func setExposureMode(_ v: AVCaptureDevice.ExposureMode) {
        send(msgType: .setExposureMode, value: v, to: nil)
    }
    
    public func setExposure(_ v: TnCameraExposureValue) {
    }
    
    public func setZoomFactor(_ v: TnCameraZoomFactorValue) {
        send(msgType: .setZoomFactor, value: v, to: nil)
    }
    
    public func setDepth(_ v: Bool) {
        send(msgType: .setDepth, value: v, to: nil)
    }
    
    public func setPortrait(_ v: Bool) {
        send(msgType: .setPortrait, value: v, to: nil)
    }
    
    public func setPriority(_ v: AVCapturePhotoOutput.QualityPrioritization) {
        send(msgType: .setQuality, value: v, to: nil)
    }
    
    public func setFocusMode(_ v: AVCaptureDevice.FocusMode) {
        send(msgType: .setFocusMode, value: v, to: nil)
    }
    
    public func setTransporting(_ v: TnCameraTransportingValue) {
        send(msgType: .setTransporting, value: v, to: nil)
    }
    
    public func setCapturing(_ v: TnCameraCapturingValue) {
        send(msgType: .setCapturing, value: v, to: nil)
    }
    
    public func createAlbum(_ v: String) {
        send(msgType: .createAlbum, value: v, to: nil)
    }
}

// MARK: TnCameraProxyProtocol
extension TnCameraProxyClient: TnCameraProxyProtocol {
    public var encoder: TnEncoder {
        ble.encoder
    }
    
    public var decoder: TnDecoder {
        ble.decoder
    }
    
    public func setup() {
        ble.setupBle()
    }
    
    public func send(data: Data, to: [String]?) async throws {
        Task { [self] in
            if networkCommon == nil {
                ble.send(data: data, to: to)
            } else {
                try? await networkCommon?.send(data: data, to: to)
            }
        }
    }

    public func sendImage() {
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
        send(msgType: .getSettings, to: nil)
    }
    
    public func tnBluetoothClient(ble: TnBluetoothClient, disconnectedID: String) {
    }
    
    public func tnBluetoothClient(ble: TnBluetoothClient, sentID: String, sentData: Data) {
    }
    
    public func tnBluetoothClient(ble: TnBluetoothClient, receivedID: String, receivedData: Data) {
        solveData(data: receivedData)
    }
}

// MARK: TnNetworkDelegate
extension TnCameraProxyClient: TnNetworkDelegate {
    public func tnNetworkReady(_ connection: TnNetworkConnection) {
        if connection.name == networkImage?.name {
            networkImage?.send(msgType: .getImage, to: nil)
        }
    }
    
    public func tnNetworkStop(_ connection: TnNetworkConnection, error: (any Error)?) {
        networkCommon = nil
        networkImage = nil
    }

    public func tnNetworkReceived(_ connection: TnNetworkConnection, data: Data) {
        Task {
            self.solveData(data: data)
        }
    }

    public func tnNetworkSent(_ connection: TnNetworkConnection, count: Int) {
    }
}
