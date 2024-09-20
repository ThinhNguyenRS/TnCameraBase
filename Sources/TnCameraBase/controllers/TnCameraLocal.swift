////
////  CameraManagerWithVideoOutput.swift
////  tCamera
////
////  Created by Thinh Nguyen on 7/26/24.
////
//
//import Foundation
//import AVFoundation
//import CoreImage
//import Combine
//import UIKit
//import TnIosBase
//
//public class TnCameraLocal: NSObject, ObservableObject, TnLoggable {
//    public static let shared = TnCameraLocal()
//    private override init() {
//    }
//    public let LOG_NAME = "TnCameraLocal"
//    
//    @Published public var currentCiImage: CIImage?
//    @Published public var settings: TnCameraSettings = .init()
//    @Published public var status: TnCameraStatus = .none
//
//    private let session = AVCaptureSession()
//    private let sessionQueue = DispatchQueue(label: "tn.tCamera.sessionQueue")
//    
//    private var videoDeviceInput: AVCaptureDeviceInput?
//    private let photoOutput = AVCapturePhotoOutput()
//    private let videoDataOutput = AVCaptureVideoDataOutput()
//                
//    typealias DoDeviceHandler = (AVCaptureDeviceInput, AVCaptureDevice) throws -> Void
////    typealias ApplyDeviceHandler = (AVCaptureDevice) -> Void
//    typealias DoSessionHandler = (TnCameraLocal) -> Void
//    
//    var captureCompletion: ((UIImage) -> Void)? = nil
//    private lazy var captureDelegator = TnCameraCaptureDelegate(completion: { uiImage in
//        self.captureCompletion?(uiImage)
//    })
//}
//
//// MARK: session
//extension TnCameraLocal {
//    private func addSessionInputs() throws {
//        self.logDebug("addSessionInputs ...")
//        
//        forceValueInRange(&settings.cameraType, TnCameraDiscover.getAvailableDeviceTpes(for: settings.cameraPosition))
//
//        guard let device = AVCaptureDevice.default(settings.cameraType, for: .video, position: settings.cameraPosition) else {
//            throw TnAppError.general(message: "Video device is unavailable: [\(settings.cameraType.description)]")
//        }
//        
//        let deviceInput = try AVCaptureDeviceInput(device: device)
//        if !session.canAddInput(deviceInput) {
//            throw TnAppError.general(message: "Cannot add device input [\(deviceInput.device.deviceType.description)] to the session")
//        }
//        session.addInput(deviceInput)
//        videoDeviceInput = deviceInput
//        
//        self.logDebug("addSessionInputs !")
//    }
//    
//    private func addSessionOutputs() throws {
//        self.logDebug("addSessionOutputs ...")
//        
//        // photo output
//        if !session.canAddOutput(photoOutput) {
//            throw TnAppError.general(message: "Cannot add photo output to the session")
//        }
//        session.addOutput(photoOutput)
//        photoOutput.maxPhotoQualityPrioritization = settings.priority // prioritize quality
//        photoOutput.orientation = .portrait
//        
//        if photoOutput.isDepthDataDeliverySupported {
//            photoOutput.isDepthDataDeliveryEnabled = settings.depth
//        }
//
//        if photoOutput.isPortraitEffectsMatteDeliverySupported {
//            photoOutput.isPortraitEffectsMatteDeliveryEnabled = settings.portrait
//        }
//
//        // video output
//        let sampleBufferQueue = DispatchQueue(label: "tn.tCamera.sampleBufferQueue")
//        videoDataOutput.setSampleBufferDelegate(self, queue: sampleBufferQueue)
//        videoDataOutput.alwaysDiscardsLateVideoFrames = true
//        // need get from settings
//        videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: settings.pixelFormat]
//        if !session.canAddOutput(videoDataOutput) {
//            throw TnAppError.general(message: "Cannot add video output to the session")
//        }
//        session.addOutput(videoDataOutput)
//        videoDataOutput.orientation = .portrait
//                
//        self.logDebug("addSessionOutputs !")
//    }
//    
//    private func doSessionQueue(_ action: @escaping DoSessionHandler) {
//        sessionQueue.async { [weak self] in
//            guard let self else { return }
//            action(self)
//        }
//    }
//
//    private func setupSession(name: String, handler: @escaping DoDeviceHandler, postHandler: DoDeviceHandler? = nil, setSettings: Bool = false) {
//        doSessionQueue { me in
//            do {
//                self.logDebug(name, "...")
//                
//                // begin config
//                me.session.beginConfiguration()
//                
//                if !me.session.canSetSessionPreset(me.settings.preset) {
//                    throw TnAppError.general(message: "Cannot set session preset: [\(me.settings.preset.rawValue)]")
//                }
//                me.session.sessionPreset = me.settings.preset
//                
//                // wide color
//                me.session.automaticallyConfiguresCaptureDeviceForWideColor = me.settings.wideColor
//
//                // Remove the current video input
//                if let deviceInput = me.videoDeviceInput {
//                    me.session.removeInput(deviceInput)
//                }
//
//                // add inputs
//                try me.addSessionInputs()
//                
//                // call handler
//                guard let deviceInput = me.videoDeviceInput else {
//                    throw TnAppError.general(message: "Cannot get device input")
//                }
//                let device = deviceInput.device
//                
//                try handler(deviceInput, device)
//
//                // commit config
//                me.session.commitConfiguration()
//                
//                me.fetchSettings()
//                
//                // post process
//                try postHandler?(deviceInput, device)
//
//                self.logDebug(name, "!")
//            } catch {
//                me.status = .failed
//                me.session.commitConfiguration()
//                me.logError(name, error.localizedDescription)
//            }
//        }
//    }
//    
//    private func setupDevice(name: String, handler: @escaping DoDeviceHandler, postHandler: DoDeviceHandler? = nil) {
//        doSessionQueue { me in
//            guard me.status == .started, let deviceInput = me.videoDeviceInput else { return }
//            let device = deviceInput.device
//            do {
//                try device.lockForConfiguration()
//                                
//                try handler(deviceInput, device)
//
//                device.unlockForConfiguration()
//
//                try postHandler?(deviceInput, device)
//            } catch {
//                device.unlockForConfiguration()
//                me.logError(name, error.localizedDescription)
//            }
//        }
//    }
//
//    private func getDevice(_ handler: @escaping DoDeviceHandler) {
//        guard status == .started, let deviceInput = self.videoDeviceInput else { return }
//        try? handler(deviceInput, deviceInput.device)
//    }
//    
//    func startSession(completion: (() -> Void)? = nil) {
//        self.setupSession(
//            name: "startSession",
//            handler: { [self] deviceInput, device in
//                // outputs
//                try addSessionOutputs()
//                status = .inited
//            },
//            postHandler: { [self] deviceInput, device in
//                // start running
//                session.startRunning()
//                status = .started
//                completion?()
//            }
//        )
//    }
//}
//
//// MARK: AVCaptureVideoDataOutputSampleBufferDelegate
//extension TnCameraLocal: AVCaptureVideoDataOutputSampleBufferDelegate {
//    public func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
//    }
//    
//    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
//        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
//            return
//        }
//        self.currentCiImage = CIImage(cvImageBuffer: pixelBuffer)
//    }
//}
//
//// MARK: public functions
//extension TnCameraLocal {
//    public func startCapturing() {
//        doSessionQueue { me in
//            if me.status < .inited {
//                me.startSession()
//            } else {
//                if !me.session.isRunning {
//                    me.session.startRunning()
//                    me.status = .started
//                }
//            }
//        }
//    }
//    
//    public func stopCapturing() {
//        doSessionQueue { me in
//            if me.session.isRunning {
//                me.session.startRunning()
//                me.status = .started
//            }
//        }
//    }
//    
//    public func toggleCapturing() {
//        doSessionQueue { me in
//            if me.status < .inited {
//                me.startSession()
//            } else {
//                if me.session.isRunning {
//                    me.session.stopRunning()
//                    me.status = .inited
//                } else {
//                    me.session.startRunning()
//                    me.status = .started
//                }
//            }
//        }
//    }
//    
//    public func switchCamera() {
//        settings.cameraPosition = settings.cameraPosition.toggle()
//        // change cameratype if necessary
//        forceValueInRange(&settings.cameraType, TnCameraDiscover.getAvailableDeviceTpes(for: settings.cameraPosition))
//        
//        self.setupSession(
//            name: "switchCamera",
//            handler: {_,_ in },
//            postHandler: { [self] deviceInput, device in
//                videoDataOutput.orientation = .portrait
//            }
//        )
//    }
//    
//    public func setLivephoto(_ v: Bool) {
//        doSessionQueue { [self] _ in
//            if settings.livephotoSupported {
//                photoOutput.isLivePhotoCaptureEnabled = v
//                settings.livephoto = v
//            }
//        }
//    }
//    
//    public func setFlash(_ v: AVCaptureDevice.FlashMode) {
//        if settings.flashSupported {
//            settings.flashMode = v
//        }
//    }
//    
//    public func setHDR(_ v: TnTripleState) {
//        doSessionQueue { [self] _ in
//            let device = videoDeviceInput!.device
//            
//            session.beginConfiguration()
//            do {
//                try device.lockForConfiguration()
//                
//                switch v {
//                case .auto:
//                    device.automaticallyAdjustsVideoHDREnabled = true
//                default:
//                    device.automaticallyAdjustsVideoHDREnabled = false
//                    device.isVideoHDREnabled = v.toBool()!
//                }
//                
//                settings.hdr = v
//            } catch {
//                TnLogger.error(LOG_NAME, "setHDR", error.localizedDescription)
//            }
//            device.unlockForConfiguration()
//            session.commitConfiguration()
//        }
//    }
//    
//    public func setPreset(_ v: AVCaptureSession.Preset) {
//        if settings.preset != v && session.canSetSessionPreset(v) {
//            settings.preset = v
//            setupSession(
//                name: "setPreset",
//                handler: { _,_ in },
//                postHandler: { [self] _,_ in
//                    videoDataOutput.orientation = .portrait
//                }
//            )
//        }
//    }
//    
//    public func setCameraType(_ v: AVCaptureDevice.DeviceType) {
//        if settings.cameraType != v {
//            settings.cameraType = v
//            setupSession(
//                name: "setCameraType",
//                handler: { _,_ in },
//                postHandler: { [self] _,_ in
//                    videoDataOutput.orientation = .portrait
//                }
//            )
//        }
//    }
//    
//    public func setExposureMode(_ v: AVCaptureDevice.ExposureMode) {
//        if settings.exposureMode != v {
//            setupDevice(
//                name: "setExposureMode",
//                handler: { _, device in
//                    device.exposureMode = v
//                },
//                postHandler: {_,_ in
//                    self.fetchSettings()
//                }
//            )
//        }
//    }
//    
//    public func setExposure(_ v: TnCameraExposureValue) {
//        if settings.exposureMode == .custom {
//            setupDevice(
//                name: "setExposure",
//                handler: { _, device in
//                    device.setExposureModeCustom(
//                        duration: v.duration == nil ? AVCaptureDevice.currentExposureDuration : CMTime(seconds: v.duration!, preferredTimescale: device.exposureDuration.timescale),
//                        iso: v.iso ?? AVCaptureDevice.currentISO
//                    )
//                },
//                postHandler: {_,_ in
//                    self.fetchSettings()
//                }
//            )
//        }
//    }
//    
//    public func setZoomFactor(_ v: TnCameraZoomFactorValue) {
//        if !settings.zoomRange.contains(v.value) {
//            return
//        }
//        var newV = v.value * settings.zoomMainFactor
//        self.setupDevice(
//            name: "setZoomFactor",
//            handler: { [self] _, device in
//                if v.adjust {
//                    newV = getValueInRange(device.videoZoomFactor + v.value - 1, device.minAvailableVideoZoomFactor, device.maxAvailableVideoZoomFactor)
//                }
//                if newV != device.videoZoomFactor {
//                    device.ramp(toVideoZoomFactor: newV, withRate: v.withRate * Float(settings.zoomMainFactor))
//                    settings.zoomFactor = v.value
//                }
//            }
//        )
//    }
//    
//    public func setDepth(_ v: Bool) {
//        if !settings.depthSupported {
//            return
//        }
//        
//        guard let device = videoDeviceInput?.device else {
//            return
//        }
//        
//        doSessionQueue { [self] _ in
//            session.beginConfiguration()
//            
//            photoOutput.isDepthDataDeliveryEnabled = v
//            if v {
//                let depthFormat = device.getDepthFormat(mediaSubTypes: [kCVPixelFormatType_DepthFloat32])
//                if depthFormat != nil {
//                    do {
//                        try device.lockForConfiguration()
//                        device.activeDepthDataFormat = depthFormat
//                        device.unlockForConfiguration()
//                        
//                        if let depthFormat = device.activeDepthDataFormat {
//                            logDebug("current depth mediaSubType", depthFormat.formatDescription.mediaSubType)
//                        }
//                    } catch {
//                    }
//                }
//            }
//            
//            session.commitConfiguration()
//            
//            settings.depth = photoOutput.isDepthDataDeliveryEnabled
//        }
//    }
//    
//    public func setPortrait(_ v: Bool) {
//        if !settings.portraitSupported {
//            return
//        }
//        doSessionQueue { [self] _ in
//            session.beginConfiguration()
//            photoOutput.isPortraitEffectsMatteDeliveryEnabled = v
//            session.commitConfiguration()
//            
//            settings.portrait = photoOutput.isPortraitEffectsMatteDeliveryEnabled
//        }
//    }
//    
//    public func setQuality(_ v: AVCapturePhotoOutput.QualityPrioritization) {
//        settings.priority = v
//    }
//    
//    public func setFocusMode(_ v: AVCaptureDevice.FocusMode) {
//        setupDevice(name: "setFocusMode", handler: { _, device in
//            device.focusMode = v
//        })
//    }
//    
//    public func setTransport(_ v: TnCameraTransportValue) {
//        if let scale = v.scale {
//            settings.transportScale = scale
//        }
//        if let imageCompressQuality = v.compressQuality {
//            settings.transportCompressQuality = imageCompressQuality
//        }
//        if let imageContinuous = v.continuous {
//            settings.transportContinuous = imageContinuous
//        }
//    }
//}
//
//// MARK: config misc
//extension TnCameraLocal {
//    private func fetchSettings() {
//        let deviceInput = videoDeviceInput!, device = deviceInput.device
//        
//        settings.cameraPosition = device.position
//        settings.cameraTypes = TnCameraDiscover.getAvailableDeviceTpes(for: settings.cameraPosition)
//        
//        settings.livephotoSupported = photoOutput.isLivePhotoCaptureSupported
//        settings.livephoto = photoOutput.isLivePhotoCaptureEnabled
//        
//        settings.flashModes = photoOutput.supportedFlashModes
//        
//        settings.hdrSupported = device.activeFormat.isVideoHDRSupported
//        settings.hdr = .fromTwoBool(device.automaticallyAdjustsVideoHDREnabled, device.isVideoHDREnabled)
//        
//        // zoom
//        calcZoomFactors()
//        
//        // exposure
//        settings.exposureMode = device.exposureMode
//        settings.exposureModes = AVCaptureDevice.ExposureMode.allCases.filter { v in
//            device.isExposureModeSupported(v)
//        }
//        settings.exposureSupported = !settings.exposureModes.isEmpty
//        
//        settings.isoSupported = device.isExposureModeSupported(.custom)
//        settings.isoRange = device.activeFormat.minISO ... device.activeFormat.maxISO
//        settings.iso = device.iso
//        
//        settings.exposureDuration = device.exposureDuration.seconds
//        if settings.exposureDuration.isNaN {
//            settings.exposureDuration = 0
//        }
//        settings.exposureDurationRange = device.activeFormat.minExposureDuration.seconds ... device.activeFormat.maxExposureDuration.seconds
//        
//        settings.depthSupported = photoOutput.isDepthDataDeliverySupported
//        settings.depth = photoOutput.isDepthDataDeliveryEnabled
//        
//        settings.portraitSupported = photoOutput.isPortraitEffectsMatteDeliverySupported
//        settings.portrait = photoOutput.isPortraitEffectsMatteDeliveryEnabled
//        
//        settings.priority = photoOutput.maxPhotoQualityPrioritization
//        
//        settings.focusMode = device.focusMode
//        settings.focusModes = AVCaptureDevice.FocusMode.allCases.filter { v in
//            device.isFocusModeSupported(v)
//        }
//    }
//    
//    private func calcZoomFactors() {
//        let device = videoDeviceInput!.device
//        
//        // virtualDeviceSwitchOverVideoZoomFactors will not include `1` for the widest device
//        var mainZoomFactor: CGFloat = 2
//        var relativeZoomFactors: [CGFloat] = [0.5, 1, 2]
//        let virtualZoomFactors = [1] + device.virtualDeviceSwitchOverVideoZoomFactors.map { CGFloat($0.floatValue) }
//        if virtualZoomFactors.count > 1, let wideIndex = device.constituentDevices.firstIndex(where: {d in d.deviceType == .builtInWideAngleCamera}) {
//            mainZoomFactor = virtualZoomFactors[wideIndex]
//            relativeZoomFactors = virtualZoomFactors.map { $0/mainZoomFactor }
//        }
//        relativeZoomFactors = relativeZoomFactors + [relativeZoomFactors.last!*2, relativeZoomFactors.last!*4]
//        
//        settings.zoomMainFactor = mainZoomFactor
//        settings.zoomRelativeFactors = relativeZoomFactors
//        settings.zoomRange = relativeZoomFactors.first! ... relativeZoomFactors.last!
//        settings.zoomFactor = device.videoZoomFactor / mainZoomFactor
//    }
//}
//
//// MARK: captureImage
//extension TnCameraLocal {
//    public func captureImage() {
//        doSessionQueue { me in
//            me.getDevice { _, device in
//                var p: AVCapturePhotoSettings!
//                // Capture HEVC photos when supported
//                if me.photoOutput.availablePhotoCodecTypes.contains(.hevc) {
//                    p = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
//                } else {
//                    p = .init()
//                }
//                p.flashMode = me.settings.flashMode
//                
//                // Sets the preview thumbnail pixel format
//                if let previewPhotoPixelFormatType = p.availablePreviewPhotoPixelFormatTypes.first {
//                    p.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPhotoPixelFormatType]
//                }
//                me.photoOutput.maxPhotoQualityPrioritization = me.settings.priority
//                p.photoQualityPrioritization = me.settings.priority
//                
//                // depth
//                if me.settings.depthSupported {
//                    p.isDepthDataDeliveryEnabled = me.settings.depth
//                    p.embedsDepthDataInPhoto = me.settings.depth
//                }
//                
//                // portrait
//                if me.settings.portraitSupported {
//                    p.isPortraitEffectsMatteDeliveryEnabled = me.settings.portrait
//                    p.embedsPortraitEffectsMatteInPhoto = me.settings.portrait
//                }
//                
//                me.photoOutput.orientation = .fromUI(DeviceMotionOrientationListener.shared.orientation)
//                
//                if me.photoOutput.isLivePhotoCaptureEnabled {
//                    let filePath = "\(NSTemporaryDirectory())\(UUID().uuidString).mov"
//                    p.livePhotoMovieFileURL = .init(fileURLWithPath: filePath)
//                }
//                me.photoOutput.capturePhoto(with: p, delegate: me.captureDelegator)
//            }
//        }
//    }
//}
