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
import TnIosPackage

public class TnCameraProxyClient: NSObject, ObservableObject, TnLoggable {
    public let LOG_NAME = "CameraBluetoothClient"

    @Published public private(set) var currentCiImage: CIImage?
    @Published public private(set) var settings: TnCameraSettings = .init()
    @Published public private(set) var status: TnCameraStatus = .none
    
    private let ble: TnBluetoothClient
    private var network: TnNetworkConnection?
    private let bluetooth: TnBluetoothServiceInfo
    
    public init(bluetooth: TnBluetoothServiceInfo) {
        self.bluetooth = bluetooth
        self.ble = .init(info: bluetooth)
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
    
    public func startCapturing(completion: (() -> Void)?) {
    }
    
    public func stopCapturing(completion: (() -> Void)?) {
    }
    
    public func toggleCapturing(completion: (() -> Void)?) {
        send(.toggleCapturing)
    }
    
    public func switchCamera(completion: (() -> Void)?) {
        send(.switchCamera)
    }
    
    public func captureImage(completion: @escaping (UIImage) -> Void) {
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
    
    public func setExposureMode(_ v: AVCaptureDevice.ExposureMode) {
        send(.setExposureMode, v)
    }
    
    public func setExposure(iso: Float? = nil, duration: Double? = nil) {
    }
    
    public func setZoomFactor(_ newValue: CGFloat, adjust: Bool = false, withRate: Float = 2, completion: (() -> Void)? = nil) {
        send(TnCameraMessageSetZoomFactorRequest(value: newValue, adjust: adjust, withRate: withRate))
    }
    
    public func setDepth(_ v: Bool) {
        send(.setDepth, v)
    }
    
    public func setPortrait(_ v: Bool) {
        send(.setPortrait, v)
    }
    
    public func setQuality(_ v: AVCapturePhotoOutput.QualityPrioritization) {
        send(.setQuality, v)
    }
    
    public func setFocusMode(_ v: AVCaptureDevice.FocusMode) {
        send(.setFocusMode, v)
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
            ble.send(object: object)
        } else {
            network?.send(object: object)
        }
    }
    
    private func solveMsg<TMessage: Codable>(_ receivedMsg: TnMessage, handler: (TMessage) -> Void) {
        if let msg: TMessage = receivedMsg.toObject() {
            handler(msg)
        }
    }
    
    func solveData(data: Data) {
        let receivedMsg = TnMessage(data: data)
        let messageType: TnCameraMessageType = .init(rawValue: receivedMsg.typeCode)!
        TnLogger.debug(LOG_NAME, "receive", messageType)
        
        switch messageType {
        case .getSettingsResponse:
            solveMsg(receivedMsg) { (msg: TnCameraMessageSettingsResponse) in
                self.status = msg.status
                self.settings = msg.settings
                // connect to TCP
                if network == nil {
                    if let ipHost = msg.ipHost, let ipPort = msg.ipPort {
                        network = .init(host: ipHost, port: ipPort, queue: nil, delegate: self, eom: bluetooth.EOM)
                        network?.start()
                    }
                }
            }
        case .getImageResponse:
            solveMsg(receivedMsg) { (msg: TnCameraMessageImageResponse) in
                let uiImage: UIImage = .init(data: msg.jpegData!)!
                TnLogger.debug(LOG_NAME, "image", uiImage.size.width, uiImage.size.height)

                let ciImage = CIImage(image: uiImage)!
                self.currentCiImage = ciImage
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
