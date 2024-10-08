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
    private var network: TnNetworkConnection?
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
        let receivedMsg = TnMessage(data: data)
        guard let messageType: TnCameraMessageType = .init(rawValue: receivedMsg.typeCode) else { return }
        logDebug("receive", messageType)

        switch messageType {
        case .getSettingsResponse:
            solveMsgValue(receivedMsg) { (v: TnCameraSettingsValue) in
                settings = v.settings
                delegate?.tnCamera(settings: v.settings)

                if status != v.status {
                    status = v.status
                    delegate?.tnCamera(status: v.status)
                }

                if network == nil, let hostInfo = v.network {
                    network = .init(hostInfo: hostInfo, delegate: self, transportingInfo: transportingInfo)
                    network!.start()
                }
            }
            
        case .getImageResponse:
            solveMsgValue(receivedMsg) { (v: Data) in
                let uiImage: UIImage = .init(data: v)!
                logDebug("image", uiImage.size.width, uiImage.size.height, uiImage.scale)

                let ciImage = CIImage(image: uiImage)!
                self.currentCiImage = ciImage
                
                if status == .started && (settings?.transporting.continuous ?? false) {
                    send(.getImage)
                }
            }

        case .getAlbumsResponse:
            solveMsgValue(receivedMsg) { (v: [String]) in
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
        send(.startCapturing)
    }
    
    public func stopCapturing() {
        send(.stopCapturing)
    }
    
    public func toggleCapturing() {
        send(.toggleCapturing)
    }
    
    public func switchCamera() {
        send(.switchCamera)
    }
    
    public func captureImage() {
        send(.captureImage)
    }
    
    public func setLivephoto(_ v: Bool) {
        send(.setLivephoto, v)
    }
    
    public func setFlash(_ v: AVCaptureDevice.FlashMode) {
        send(.setFlash, v)
    }
    
    public func setHDR(_ v: TnTripleState) {
        send(.setHDR, v)
    }
    
    public func setPreset(_ v: AVCaptureSession.Preset) {
        send(.setPreset, v)
    }
    
    public func setCameraType(_ v: AVCaptureDevice.DeviceType) {
        send(.setCameraType, v)
    }
    
    public func setWideColor(_ v: Bool) {
        send(.setWideColor, v)
    }
    
    public func setExposureMode(_ v: AVCaptureDevice.ExposureMode) {
        send(.setExposureMode, v)
    }
    
    public func setExposure(_ v: TnCameraExposureValue) {
    }
    
    public func setZoomFactor(_ v: TnCameraZoomFactorValue) {
        send(.setZoomFactor, v)
    }
    
    public func setDepth(_ v: Bool) {
        send(.setDepth, v)
    }
    
    public func setPortrait(_ v: Bool) {
        send(.setPortrait, v)
    }
    
    public func setPriority(_ v: AVCapturePhotoOutput.QualityPrioritization) {
        send(.setQuality, v)
    }
    
    public func setFocusMode(_ v: AVCaptureDevice.FocusMode) {
        send(.setFocusMode, v)
    }
    
    public func setTransporting(_ v: TnCameraTransportingValue) {
        send(.setTransporting, v)
    }
    
    public func setCapturing(_ v: TnCameraCapturingValue) {
        send(.setCapturing, v)
    }
    
    public func createAlbum(_ v: String) {
        send(.createAlbum, v)
    }
}

// MARK: TnCameraProxyProtocol
extension TnCameraProxyClient: TnCameraProxyProtocol {
    public var decoder: TnDecoder {
        ble.decoder
    }
    
    public func setup() {
        ble.setupBle()
    }

    public func send(_ object: TnCameraMessageProtocol, useBle: Bool = false) {
        Task {
            if useBle || network == nil {
                try? await ble.send(object: object)
            } else {
                try? await network?.send(object: object)
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
        send(.getSettings, useBle: true)
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
    }
    
    public func tnNetworkStop(_ connection: TnNetworkConnection, error: (any Error)?) {
        network = nil
    }

    public func tnNetworkReceived(_ connection: TnNetworkConnection) {
        connection.processMsgQueue { msgData in
            self.solveData(data: msgData)
        }
    }
    
    public func tnNetworkSent(_ connection: TnNetworkConnection) {
    }
}
