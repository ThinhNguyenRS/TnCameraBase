//
//  CameraSettings.swift
//  tCamera
//
//  Created by Thinh Nguyen on 7/15/24.
//

import Foundation
import AVFoundation
import UIKit
import TnIosPackage

// MARK: CameraStatus
public enum CameraStatus: Int, Comparable, Codable {
    case none
    case failed
    case inited
    case started
}

public struct TnCameraSettings: Codable {
    var presets: [AVCaptureSession.Preset] = [.photo, .hd4K3840x2160]
    var preset: AVCaptureSession.Preset = .hd4K3840x2160
    var cameraPosition: AVCaptureDevice.Position = .back

    var cameraType: AVCaptureDevice.DeviceType = .builtInTripleCamera /*.builtInWideAngleCamera*/ /*.builtInUltraWideCamera*/
    var cameraTypes: [AVCaptureDevice.DeviceType] = []
    
    
    var flashModes: [AVCaptureDevice.FlashMode] = []
    var flashMode: AVCaptureDevice.FlashMode = .auto
    var flashSupported: Bool {
        !flashModes.isEmpty
    }
    
    
    var torchSupported = false
    var torchMode: AVCaptureDevice.TorchMode = .auto
    
    var focusEnabled = false
    var focusPoint = CGPoint()
    
    var zoomFactor: CGFloat = 1.0
    var zoomRange: ClosedRange<CGFloat> = 0...1
    var zoomRelativeFactors: [CGFloat] = []
    var zoomMainFactor: CGFloat = 2
    
    var livephoto: Bool = false
    var livephotoSupported: Bool = false
    
    var hdr: TnTripleState = .auto
    var hdrSupported = false
    
    
    var exposureSupported = false
    var exposureModes: [AVCaptureDevice.ExposureMode] = []
    var exposureMode: AVCaptureDevice.ExposureMode = .locked
    
    var isoSupported = false
    var iso: Float = 0
    var isoRange: ClosedRange<Float> = 0...0
    
    var exposureDuration: Double = .zero
    var exposureDurationRange: ClosedRange<Double> = .zero ... .zero
    
    var depthSupported = false
    var depth = false
    
    var portraitSupported = false
    var portrait = false
    
    var quality: AVCapturePhotoOutput.QualityPrioritization = .quality
    
    var focusMode: AVCaptureDevice.FocusMode = .autoFocus
    var focusModes: [AVCaptureDevice.FocusMode] = []
    
    var wideColor = true
}

