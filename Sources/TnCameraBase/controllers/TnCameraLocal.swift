//
//  CameraManagerWithVideoOutput.swift
//  tCamera
//
//  Created by Thinh Nguyen on 7/26/24.
//

import Foundation
import AVFoundation
import CoreImage
import Combine
import UIKit
import TnIosBase

public class TnCameraLocal: NSObject, ObservableObject, TnLoggable {
    public static let shared = TnCameraLocal()
    private override init() {
    }
    public let LOG_NAME = "CameraLocal"
    
    @Published public var currentCiImage: CIImage?
    @Published public var settings: TnCameraSettings = .init()
    @Published public var status: TnCameraStatus = .none

    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "tn.tCamera.sessionQueue")
    
    private var videoDeviceInput: AVCaptureDeviceInput?
    private let photoOutput = AVCapturePhotoOutput()
    private let videoDataOutput = AVCaptureVideoDataOutput()
                
    typealias ApplyDeviceInputThrowableHandler = (_: AVCaptureDeviceInput, _: AVCaptureDevice) throws -> Void
    typealias ApplyDeviceHandler = (_: AVCaptureDevice) -> Void
    typealias SessionAsyncHandler = (_: TnCameraLocal) -> Void
    
    var captureImageCompletion: ((UIImage) -> Void)? = nil
    private lazy var captureDelegator = TnCameraCaptureDelegate(completion: { uiImage in
        self.captureImageCompletion?(uiImage)
    })
}

// MARK: session
extension TnCameraLocal {
    private func addSessionInputs() throws {
        self.logDebug("addSessionInputs ...")
        
        forceValueInRange(&settings.cameraType, TnCameraDiscover.getAvailableDeviceTpes(for: settings.cameraPosition))

        guard let device = AVCaptureDevice.default(settings.cameraType, for: .video, position: settings.cameraPosition) else {
            throw TnAppError.general(message: "Video device is unavailable: [\(settings.cameraType.description)]")
        }
        
        let deviceInput = try AVCaptureDeviceInput(device: device)
        if !session.canAddInput(deviceInput) {
            throw TnAppError.general(message: "Cannot add device input [\(deviceInput.device.deviceType.description)] to the session")
        }
        session.addInput(deviceInput)
        videoDeviceInput = deviceInput
        
        self.logDebug("addSessionInputs !")
    }
    
    private func addSessionOutputs() throws {
        self.logDebug("addSessionOutputs ...")
        
        // photo output
        if !session.canAddOutput(photoOutput) {
            throw TnAppError.general(message: "Cannot add photo output to the session")
        }
        session.addOutput(photoOutput)
        photoOutput.maxPhotoQualityPrioritization = .quality // prioritize quality
        photoOutput.orientation = .portrait
        photoOutput.isPortraitEffectsMatteDeliveryEnabled = photoOutput.isPortraitEffectsMatteDeliverySupported
        photoOutput.isDepthDataDeliveryEnabled = photoOutput.isDepthDataDeliverySupported

        // video output
        let sampleBufferQueue = DispatchQueue(label: "tn.tCamera.sampleBufferQueue")
        videoDataOutput.setSampleBufferDelegate(self, queue: sampleBufferQueue)
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
//        videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCMPixelFormat_32BGRA)]
        videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
//        videoDataOutput.videoSettings = [
//            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)
//        ]
        if !session.canAddOutput(videoDataOutput) {
            throw TnAppError.general(message: "Cannot add video output to the session")
        }
        session.addOutput(videoDataOutput)
        videoDataOutput.orientation = .portrait
                
        self.logDebug("addSessionOutputs !")
    }
    
    private func sessionAsync(_ action: @escaping SessionAsyncHandler) {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            action(self)
        }
    }

    private func applySession(name: String, handler: @escaping ApplyDeviceInputThrowableHandler, postHandler: ApplyDeviceInputThrowableHandler? = nil, setSettings: Bool = false) {
        sessionAsync { me in
            do {
                self.logDebug(name, "...")
                
                // begin config
                me.session.beginConfiguration()
                
                if !me.session.canSetSessionPreset(me.settings.preset) {
                    throw TnAppError.general(message: "Cannot set session preset: [\(me.settings.preset.rawValue)]")
                }
                me.session.sessionPreset = me.settings.preset
                
                // wide color
                me.session.automaticallyConfiguresCaptureDeviceForWideColor = me.settings.wideColor

                // Remove the current video input
                if let deviceInput = me.videoDeviceInput {
                    me.session.removeInput(deviceInput)
                }

                // add inputs
                try me.addSessionInputs()
                
                // call handler
                guard let deviceInput = me.videoDeviceInput else {
                    throw TnAppError.general(message: "Cannot get device input")
                }
                let device = deviceInput.device
                
                try handler(deviceInput, device)

                // commit config
                me.session.commitConfiguration()
                
                me.fetchSettings()
                
                // post process
                try postHandler?(deviceInput, device)

                self.logDebug(name, "!")
            } catch {
                me.status = .failed
                me.session.commitConfiguration()
                me.logError(name, error.localizedDescription)
            }
        }
    }
    
    private func applyDevice(name: String, handler:ApplyDeviceInputThrowableHandler?, postHandler: ApplyDeviceInputThrowableHandler? = nil) {
        sessionAsync { me in
            guard me.status == .started, let deviceInput = me.videoDeviceInput else { return }
            let device = deviceInput.device
            do {
                defer {
                    device.unlockForConfiguration()
                }
                try device.lockForConfiguration()
                                
                try handler?(deviceInput, device)

                try postHandler?(deviceInput, device)
            } catch {
                me.logError(name, error.localizedDescription)
            }
        }
    }

    private func getDevice(_ handler: @escaping ApplyDeviceHandler) {
        guard status == .started, let device = self.videoDeviceInput?.device else { return }
        handler(device)
    }
    
    func startSession(completion: (() -> Void)? = nil) {
        self.applySession(
            name: "startSession",
            handler: { [self] deviceInput, device in
                // outputs
                try addSessionOutputs()
                status = .inited
            },
            postHandler: { [self] deviceInput, device in
                // start running
                session.startRunning()
                status = .started
                completion?()
            }
        )
    }
    
//    func stopSession(handler: @escaping () -> Void) {
//        sessionQueue.async { [weak self] in
//            guard let self, configured else {
//                return
//            }
//
//            self.logDebug("stopSession ...")
//
//            if self.session.isRunning {
//                self.session.stopRunning()
//            }
//
//            session.beginConfiguration()
//
//            session.removeInput(videoDeviceInput!)
//            //            session.removeOutput(photoOutput)
//            session.removeOutput(videoDataOutput)
//
//            session.commitConfiguration()
//
//            configured = false
//
//            self.logDebug("stopSession !")
//
//            handler()
//        }
//    }
//
//    func toggleSession(handler: @escaping () -> Void) {
//        sessionQueue.async { [weak self] in
//            guard let self else {
//                return
//            }
//
//            if configured {
//                stopSession(handler: handler)
//            } else {
//                startSession(handler: handler)
//            }
//        }
//    }
}

// MARK: AVCaptureVideoDataOutputSampleBufferDelegate
extension TnCameraLocal: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    }
    
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        self.currentCiImage = CIImage(cvImageBuffer: pixelBuffer)
    }
}

// MARK: CameraManagerProtocol
extension TnCameraLocal: TnCameraProtocol {
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
        sessionAsync { me in
            if me.status < .inited {
                me.startSession(completion: completion)
            } else {
                if !me.session.isRunning {
                    me.session.startRunning()
                    me.status = .started
                    completion?()
                }
            }
        }
    }
    
    public func stopCapturing(completion: (() -> Void)?) {
        sessionAsync { me in
            if me.session.isRunning {
                me.session.startRunning()
                me.status = .started
                completion?()
            }
        }
    }
    
    public func toggleCapturing(completion: (() -> Void)?) {
        sessionAsync { me in
            if me.status < .inited {
                me.startSession(completion: completion)
            } else {
                if me.session.isRunning {
                    me.session.stopRunning()
                    me.status = .inited
                    completion?()
                } else {
                    me.session.startRunning()
                    me.status = .started
                    completion?()
                }
            }
        }
    }
    
    public func switchCamera(completion: (() -> Void)? = nil) {
        settings.cameraPosition = settings.cameraPosition.toggle()
        // change cameratype if necessary
        forceValueInRange(&settings.cameraType, TnCameraDiscover.getAvailableDeviceTpes(for: settings.cameraPosition))
        
        self.applySession(
            name: "switchCamera",
            handler: {_,_ in },
            postHandler: { [self] deviceInput, device in
                videoDataOutput.orientation = .portrait
                completion?()
            }
        )
    }
    
    public func setLivephoto(_ v: Bool) {
        sessionAsync { [self] _ in
            if settings.livephotoSupported {
                if session.isRunning {
                    session.stopRunning()
                }
//                session.removeOutput(photoOutput)
                
                session.beginConfiguration()
                photoOutput.isLivePhotoCaptureEnabled = v
                session.commitConfiguration()
                
                session.startRunning()
                settings.livephoto = photoOutput.isLivePhotoCaptureEnabled
            }
        }
    }
    
    public func setFlash(_ v: AVCaptureDevice.FlashMode) {
        if settings.flashSupported {
            settings.flashMode = v
        }
    }
    
    public func setHDR(_ v: TnTripleState) {
        sessionAsync { [self] _ in
            let device = videoDeviceInput!.device
            
            session.beginConfiguration()
            do {
                try device.lockForConfiguration()
                
                switch v {
                case .auto:
                    device.automaticallyAdjustsVideoHDREnabled = true
                default:
                    device.automaticallyAdjustsVideoHDREnabled = false
                    device.isVideoHDREnabled = v.toBool()!
                }
                
                settings.hdr = v
            } catch {
                TnLogger.error(LOG_NAME, "setHDR", error.localizedDescription)
            }
            device.unlockForConfiguration()
            session.commitConfiguration()
        }
    }
    
    public func setPreset(_ v: AVCaptureSession.Preset) {
        if settings.preset != v && session.canSetSessionPreset(v) {
            settings.preset = v
            applySession(
                name: "setPreset",
                handler: { _,_ in },
                postHandler: { [self] _,_ in
                    videoDataOutput.orientation = .portrait
                }
            )
        }
    }
    
    public func setCameraType(_ v: AVCaptureDevice.DeviceType) {
        if settings.cameraType != v {
            settings.cameraType = v
            applySession(
                name: "setCameraType",
                handler: { _,_ in },
                postHandler: { [self] _,_ in
                    videoDataOutput.orientation = .portrait
                }
            )
        }
    }
    
    public func setExposureMode(_ v: AVCaptureDevice.ExposureMode) {
        if settings.exposureMode != v {
            applyDevice(
                name: "setExposureMode",
                handler: { _, device in
                    device.exposureMode = v
                },
                postHandler: {_,_ in
                    self.fetchSettings()
                }
            )
        }
    }
    
    public func setExposure(iso: Float? = nil, duration: Double? = nil) {
        if settings.exposureMode == .custom {
            applyDevice(
                name: "setExposure",
                handler: { _, device in
                    device.setExposureModeCustom(
                        duration: duration == nil ? AVCaptureDevice.currentExposureDuration : CMTime(seconds: duration!, preferredTimescale: device.exposureDuration.timescale),
                        iso: iso ?? AVCaptureDevice.currentISO
                    )
                },
                postHandler: {_,_ in
                    self.fetchSettings()
                }
            )
        }
    }
    
    public func setZoomFactor(_ newValue: CGFloat, adjust: Bool = false, withRate: Float = 2, completion: (() -> Void)? = nil) {
        if !settings.zoomRange.contains(newValue) {
            return
        }
        var v = newValue * settings.zoomMainFactor
        self.applyDevice(
            name: "setZoomFactor",
            handler: { [self] _, device in
                if adjust {
                    v = getValueInRange(device.videoZoomFactor + newValue - 1, device.minAvailableVideoZoomFactor, device.maxAvailableVideoZoomFactor)
                }
                if v != device.videoZoomFactor {
                    device.ramp(toVideoZoomFactor: v, withRate: withRate * Float(settings.zoomMainFactor))
                    settings.zoomFactor = newValue
                    completion?()
                }
            }
        )
    }
    
    public func setDepth(_ v: Bool) {
        if !settings.depthSupported {
            return
        }
        
        guard let device = videoDeviceInput?.device else {
            return
        }
        
        sessionAsync { [self] _ in
            session.beginConfiguration()
            
            photoOutput.isDepthDataDeliveryEnabled = v
            if v {
                let depthFormat = device.getDepthFormat(mediaSubTypes: [kCVPixelFormatType_DepthFloat32])
                if depthFormat != nil {
                    do {
                        try device.lockForConfiguration()
                        device.activeDepthDataFormat = depthFormat
                        device.unlockForConfiguration()
                        
                        if let depthFormat = device.activeDepthDataFormat {
                            logDebug("current depth mediaSubType", depthFormat.formatDescription.mediaSubType)
                        }
                    } catch {
                    }
                }
            }
            
            session.commitConfiguration()
            
            settings.depth = photoOutput.isDepthDataDeliveryEnabled
        }
    }
    
    public func setPortrait(_ v: Bool) {
        if !settings.portraitSupported {
            return
        }
        sessionAsync { [self] _ in
            session.beginConfiguration()
            photoOutput.isPortraitEffectsMatteDeliveryEnabled = v
            session.commitConfiguration()
            
            settings.portrait = photoOutput.isPortraitEffectsMatteDeliveryEnabled
        }
    }
    
    public func setQuality(_ v: AVCapturePhotoOutput.QualityPrioritization) {
        settings.quality = v
    }
    
    public func setFocusMode(_ v: AVCaptureDevice.FocusMode) {
        applyDevice(name: "setFocusMode", handler: { _, device in
            device.focusMode = v
        })
    }
}

// MARK: config misc
extension TnCameraLocal {
    private func fetchSettings() {
        let deviceInput = videoDeviceInput!, device = deviceInput.device
        
        settings.cameraPosition = device.position
        settings.cameraTypes = TnCameraDiscover.getAvailableDeviceTpes(for: settings.cameraPosition)
        
        settings.livephotoSupported = photoOutput.isLivePhotoCaptureSupported
        settings.livephoto = photoOutput.isLivePhotoCaptureEnabled
        
        settings.flashModes = photoOutput.supportedFlashModes
        
        settings.hdrSupported = device.activeFormat.isVideoHDRSupported
        settings.hdr = .fromTwoBool(device.automaticallyAdjustsVideoHDREnabled, device.isVideoHDREnabled)
        
        // zoom
        calcZoomFactors()
        
        // exposure
        settings.exposureMode = device.exposureMode
        settings.exposureModes = AVCaptureDevice.ExposureMode.allCases.filter { v in
            device.isExposureModeSupported(v)
        }
        settings.exposureSupported = !settings.exposureModes.isEmpty
        
        settings.isoSupported = device.isExposureModeSupported(.custom)
        settings.isoRange = device.activeFormat.minISO ... device.activeFormat.maxISO
        settings.iso = device.iso
        
        settings.exposureDuration = device.exposureDuration.seconds
        if settings.exposureDuration.isNaN {
            settings.exposureDuration = 0
        }
        settings.exposureDurationRange = device.activeFormat.minExposureDuration.seconds ... device.activeFormat.maxExposureDuration.seconds
        
        settings.depthSupported = photoOutput.isDepthDataDeliverySupported
        settings.depth = photoOutput.isDepthDataDeliveryEnabled
        
        settings.portraitSupported = photoOutput.isPortraitEffectsMatteDeliverySupported
        settings.portrait = photoOutput.isPortraitEffectsMatteDeliveryEnabled
        
        settings.quality = photoOutput.maxPhotoQualityPrioritization
        
        settings.focusMode = device.focusMode
        settings.focusModes = AVCaptureDevice.FocusMode.allCases.filter { v in
            device.isFocusModeSupported(v)
        }
    }
    
    private func calcZoomFactors() {
        let device = videoDeviceInput!.device
        
        // virtualDeviceSwitchOverVideoZoomFactors will not include `1` for the widest device
        var mainZoomFactor: CGFloat = 2
        var relativeZoomFactors: [CGFloat] = [0.5, 1, 2]
        let virtualZoomFactors = [1] + device.virtualDeviceSwitchOverVideoZoomFactors.map { CGFloat($0.floatValue) }
        if virtualZoomFactors.count > 1, let wideIndex = device.constituentDevices.firstIndex(where: {d in d.deviceType == .builtInWideAngleCamera}) {
            mainZoomFactor = virtualZoomFactors[wideIndex]
            relativeZoomFactors = virtualZoomFactors.map { $0/mainZoomFactor }
        }
        relativeZoomFactors = relativeZoomFactors + [relativeZoomFactors.last!*2, relativeZoomFactors.last!*4]
        
        settings.zoomMainFactor = mainZoomFactor
        settings.zoomRelativeFactors = relativeZoomFactors
        settings.zoomRange = relativeZoomFactors.first! ... relativeZoomFactors.last!
        settings.zoomFactor = device.videoZoomFactor / mainZoomFactor
    }
}

// MARK: captureImage
extension TnCameraLocal {
    public func captureImage(completion: ((UIImage) -> Void)?) {
        if completion != nil {
            self.captureImageCompletion = completion
        }
        
        sessionAsync { me in
            me.getDevice { device in
                var p: AVCapturePhotoSettings!
                // Capture HEVC photos when supported
                if me.photoOutput.availablePhotoCodecTypes.contains(.hevc) {
                    p = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
                } else {
                    p = .init()
                }
                p.flashMode = me.settings.flashMode
                
                // Sets the preview thumbnail pixel format
                if let previewPhotoPixelFormatType = p.availablePreviewPhotoPixelFormatTypes.first {
                    p.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPhotoPixelFormatType]
                }
                me.photoOutput.maxPhotoQualityPrioritization = me.settings.quality
                p.photoQualityPrioritization = me.settings.quality
                
                // depth
                if me.settings.depthSupported {
                    p.isDepthDataDeliveryEnabled = me.settings.depth
                    p.embedsDepthDataInPhoto = me.settings.depth
                }
                
                // portrait
                if me.settings.portraitSupported {
                    p.isPortraitEffectsMatteDeliveryEnabled = me.settings.portrait
                    p.embedsPortraitEffectsMatteInPhoto = me.settings.portrait
                }
                
                me.photoOutput.orientation = .fromUI(DeviceMotionOrientationListener.shared.orientation)
                
                if me.photoOutput.isLivePhotoCaptureEnabled {
                    let filePath = "\(NSTemporaryDirectory())\(UUID().uuidString).mov"
                    p.livePhotoMovieFileURL = .init(fileURLWithPath: filePath)
                }
                me.photoOutput.capturePhoto(with: p, delegate: me.captureDelegator)
            }
        }
    }
}
