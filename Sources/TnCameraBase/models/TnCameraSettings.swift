//
//  CameraSettings.swift
//  tCamera
//
//  Created by Thinh Nguyen on 7/15/24.
//

import Foundation
import AVFoundation
import UIKit
import TnIosBase

// MARK: TnCameraStatus
public enum TnCameraStatus: Int, Comparable, Codable {
    case none
    case failed
    case inited
    case started
}

// MARK: TnCameraSettings
public struct TnCameraSettings: Codable {
    public init() {
    }
    
    public var presets: [AVCaptureSession.Preset] = [.photo, .hd4K3840x2160]
    public var preset: AVCaptureSession.Preset = .hd4K3840x2160
    public var cameraPosition: AVCaptureDevice.Position = .back

    public var cameraType: AVCaptureDevice.DeviceType = .builtInTripleCamera /*.builtInWideAngleCamera*/ /*.builtInUltraWideCamera*/
    public var cameraTypes: [AVCaptureDevice.DeviceType] = []
    
    
    public var flashModes: [AVCaptureDevice.FlashMode] = []
    public var flashMode: AVCaptureDevice.FlashMode = .auto
    public var flashSupported: Bool {
        !flashModes.isEmpty
    }
    
    
    public var torchSupported = false
    public var torchMode: AVCaptureDevice.TorchMode = .auto
    
    public var focusEnabled = false
    public var focusPoint = CGPoint()
    
    public var zoomFactor: CGFloat = 1.0
    public var zoomRange: ClosedRange<CGFloat> = 0...1
    public var zoomRelativeFactors: [CGFloat] = []
    public var zoomMainFactor: CGFloat = 2
    
    public var livephoto: Bool = false
    public var livephotoSupported: Bool = false
    
    public var hdr: TnTripleState = .auto
    public var hdrSupported = false
    
    
    public var exposureSupported = false
    public var exposureModes: [AVCaptureDevice.ExposureMode] = []
    public var exposureMode: AVCaptureDevice.ExposureMode = .locked
    
    public var isoSupported = false
    public var iso: Float = 0
    public var isoRange: ClosedRange<Float> = 0...0
    
    public var exposureDuration: Double = .zero
    public var exposureDurationRange: ClosedRange<Double> = .zero ... .zero
    
    public var depthSupported = false
    public var depth = false
    
    public var portraitSupported = false
    public var portrait = false
    
    public var quality: AVCapturePhotoOutput.QualityPrioritization = .quality
    
    public var focusMode: AVCaptureDevice.FocusMode = .autoFocus
    public var focusModes: [AVCaptureDevice.FocusMode] = []
    
    public var wideColor = true
}

