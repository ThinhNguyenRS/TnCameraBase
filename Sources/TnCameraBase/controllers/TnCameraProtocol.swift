//
//  CameraProtocol.swift
//  tCamera
//
//  Created by Thinh Nguyen on 8/17/24.
//

import Foundation
import SwiftUI
import CoreImage
import Combine
import AVFoundation
import TnIosBase

// MARK: TnCameraProtocol
public protocol TnCameraProtocol {
    var delegate: TnCameraDelegate? { get set }

    var currentCiImagePublisher: Published<CIImage?>.Publisher { get async }
    var albums: [String] { get }
    
    func setup()

    func toggleCapturing()
    func startCapturing()
    func stopCapturing()
    func switchCamera()
    
    func captureImage()
    
    func setLivephoto(_ v: Bool)
    func setFlash(_ v: AVCaptureDevice.FlashMode)
    func setHDR(_ v: TnTripleState)
    func setPreset(_ v: AVCaptureSession.Preset)
    func setCameraType(_ v: AVCaptureDevice.DeviceType)
    func setZoomFactor(_ v: TnCameraZoomFactorValue)
    func setExposure(_ v: TnCameraExposureValue)
    
    func setDepth(_ v: Bool)
    func setPortrait(_ v: Bool)
    func setPriority(_ v: AVCapturePhotoOutput.QualityPrioritization)
    func setFocusMode(_ v: AVCaptureDevice.FocusMode)
    func setWideColor(_ v: Bool)
    
    func setTransporting(_ v: TnCameraTransportingValue)
    func setCapturing(_ v: TnCameraCapturingValue)
    func createAlbum(_ v: String)
}
