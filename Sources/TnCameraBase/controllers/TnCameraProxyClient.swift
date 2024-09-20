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
    public let LOG_NAME = "TnCameraProxyClient"

    @Published public private(set) var currentCiImage: CIImage?
    @Published public private(set) var settings: TnCameraSettings = .init()
    @Published public private(set) var status: TnCameraStatus = .none
    
    private let ble: TnBluetoothClient
    private var network: TnNetworkConnection?
    private let networkInfo: TnNetworkServiceInfo
    
    public init(networkInfo: TnNetworkServiceInfo) {
        self.networkInfo = networkInfo
        self.ble = .init(info: networkInfo)
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

// MARK: CameraManagerProxyProtocol
extension TnCameraProxyClient: TnCameraProxyProtocol {
    public func setup() {
        ble.setupBle()
    }
    
    public var currentCiImagePublisher: Published<CIImage?>.Publisher {
        $currentCiImage
    }
    
    public var settingsPublisher: Published<TnCameraSettings>.Publisher {
        $settings
    }
    
    public var statusPublisher: Published<TnCameraStatus>.Publisher {
        $status
    }
    
    public func startCapturing() {
    }
    
    public func stopCapturing() {
    }
    
    public func toggleCapturing() {
        send(.toggleCapturing)
    }
    
    public func switchCamera() {
        send(.switchCamera)
    }
    
    public func captureImage(_ v: TnCameraCaptureValue) {
        send(.captureImage, v)
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
    
    public func setTransport(_ v: TnCameraTransportValue) {
        send(.setTransport, v)
    }
}

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

extension TnCameraProxyClient {
    public func send(_ object: TnCameraMessageProtocol, useBle: Bool = false) {
        if useBle {
            try? ble.send(object: object)
        } else {
            try? network?.send(object: object)
        }
    }
    
    func solveData(data: Data) {
        let receivedMsg = TnMessage(data: data)
        let messageType: TnCameraMessageType = .init(rawValue: receivedMsg.typeCode)!
        logDebug("receive", messageType)

        switch messageType {
        case .getSettingsResponse:
            solveMsgValue(receivedMsg) { (v: TnCameraSettingsValue) in
                self.status = v.status
                self.settings = v.settings
                // connect to TCP
                if network == nil {
                    if let ipHost = v.ipHost, let ipPort = v.ipPort {
                        network = .init(host: ipHost, port: ipPort, queue: nil, delegate: self, EOM: networkInfo.EOM, MTU: networkInfo.MTU)
                        network?.start()
                    }
                }
            }
        case .getImageResponse:
            solveMsgValue(receivedMsg) { (v: Data) in
                let uiImage: UIImage = .init(data: v)!
                logDebug("image", uiImage.size.width, uiImage.size.height, uiImage.scale)

                let ciImage = CIImage(image: uiImage)!
                self.currentCiImage = ciImage
            }

            if settings.transportContinuous {
                send(.getImage)
            }
        default:
            return
        }
    }
}

extension TnCameraProxyClient: TnNetworkDelegate {
    public func tnNetworkReady(_ connection: TnNetworkConnection) {
    }
    
    public func tnNetworkStop(_ connection: TnNetworkConnection, error: (any Error)?) {
        network = nil
    }

    public func tnNetwork(_ connection: TnNetworkConnection, receivedData: Data) {
        self.solveData(data: receivedData)
    }
    
    public func tnNetwork(_ connection: TnNetworkConnection, sentData: Data) {
    }
}
