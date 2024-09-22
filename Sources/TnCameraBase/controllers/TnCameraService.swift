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

public actor TnCameraService: NSObject, TnLoggable {
    public static let shared: TnCameraService = .init()

    typealias DoDeviceHandler = (AVCaptureDeviceInput, AVCaptureDevice) throws -> Void

    nonisolated public let LOG_NAME = "TnCameraService"
    
    @Published public var settings: TnCameraSettings = .init()
    @Published public var status: TnCameraStatus = .none
    @Published public var currentCiImage: CIImage?
    
    private let session = AVCaptureSession()
    
    private var videoDeviceInput: AVCaptureDeviceInput?
    private let photoOutput = AVCapturePhotoOutput()
    private let videoDataOutput = AVCaptureVideoDataOutput()
    
    var captureDelegate: TnCameraCaptureDelegate? = nil

    private override init() {
    }
}


// MARK: config misc
extension TnCameraService {
    private func fetchSettings() {
        let deviceInput = videoDeviceInput!, device = deviceInput.device

        settings.cameraPosition = device.position
        settings.cameraTypes = TnCameraDiscover.getAvailableDeviceTpes(for: settings.cameraPosition)

        settings.livephotoSupported = photoOutput.isLivePhotoCaptureSupported
        settings.livephoto = photoOutput.isLivePhotoCaptureEnabled

        settings.flashModes = photoOutput.supportedFlashModes

        settings.hdrSupported = device.activeFormat.isVideoHDRSupported
        settings.hdr = .fromTwoBool(device.automaticallyAdjustsVideoHDREnabled, device.isVideoHDREnabled)

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

        settings.priority = photoOutput.maxPhotoQualityPrioritization

        settings.focusMode = device.focusMode
        settings.focusModes = AVCaptureDevice.FocusMode.allCases.filter { v in
            device.isFocusModeSupported(v)
        }

        // zoom
        calcZoomFactors()
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


// MARK: session
extension TnCameraService {
    // MARK: - Authorization
    /// A Boolean value that indicates whether a person authorizes this app to use
    /// device cameras and microphones. If they haven't previously authorized the
    /// app, querying this property prompts them for authorization.
    var isAuthorized: Bool {
        get async {
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            // Determine whether a person previously authorized camera access.
            var isAuthorized = status == .authorized
            // If the system hasn't determined their authorization status,
            // explicitly prompt them for approval.
            if status == .notDetermined {
                isAuthorized = await AVCaptureDevice.requestAccess(for: .video)
            }
            return isAuthorized
        }
    }
    
    private func addInputs() throws {
        self.logDebug("addSessionInputs ...")
        
        forceValueInRange(&settings.cameraType, TnCameraDiscover.getAvailableDeviceTpes(for: settings.cameraPosition))
        
        guard let device = AVCaptureDevice.default(settings.cameraType, for: .video, position: settings.cameraPosition) else {
            throw TnAppError.general(message: "Video device is unavailable: [\(settings.cameraType.description)]")
        }
        
        // Remove the current video input
        if let deviceInput = videoDeviceInput {
            session.removeInput(deviceInput)
        }
        
        // add video input
        let deviceInput = try AVCaptureDeviceInput(device: device)
        if !session.canAddInput(deviceInput) {
            throw TnAppError.general(message: "Cannot add device input [\(deviceInput.device.deviceType.description)] to the session")
        }
        session.addInput(deviceInput)
        videoDeviceInput = deviceInput
        
        self.logDebug("addSessionInputs !")
    }
    
    private func addOutputs() throws {
        self.logDebug("addSessionOutputs ...")
        
        // remove current outputs
        if !session.outputs.isEmpty {
            session.removeOutput(photoOutput)
            session.removeOutput(videoDataOutput)
        }
        
        // add photo output
        if !session.canAddOutput(photoOutput) {
            throw TnAppError.general(message: "Cannot add photo output to the session")
        }
        session.addOutput(photoOutput)
        photoOutput.maxPhotoQualityPrioritization = settings.priority
        photoOutput.isLivePhotoCaptureEnabled = photoOutput.isLivePhotoCaptureSupported && settings.livephoto
        photoOutput.isDepthDataDeliveryEnabled = photoOutput.isDepthDataDeliverySupported && settings.depth
        photoOutput.isPortraitEffectsMatteDeliveryEnabled = photoOutput.isPortraitEffectsMatteDeliverySupported && settings.portrait
        photoOutput.orientation = .portrait
        
        // add video output
        let sampleBufferQueue = DispatchQueue(label: "TnCameraService.sampleBufferQueue")
        videoDataOutput.setSampleBufferDelegate(self, queue: sampleBufferQueue)
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: settings.pixelFormat]
        if !session.canAddOutput(videoDataOutput) {
            throw TnAppError.general(message: "Cannot add video output to the session")
        }
        session.addOutput(videoDataOutput)
        videoDataOutput.orientation = .portrait
        
        self.logDebug("addSessionOutputs !")
    }
    
    private func setupDevice(name: String, deviceLock: Bool = false, deviceHandler: DoDeviceHandler? = nil) throws {
        if let deviceHandler {
            logDebug("setup device", name, "...")
            let deviceInput = videoDeviceInput!, device = deviceInput.device
            defer {
                if deviceLock {
                    device.unlockForConfiguration()
                }
                logDebug("setup device", name, "!")
            }
            if deviceLock {
                try device.lockForConfiguration()
            }
            
            try deviceHandler(deviceInput, device)
        }
    }
    
    private func setupSession(name: String, reset: Bool, deviceLock: Bool = false, deviceHandler: DoDeviceHandler? = nil) throws {
        guard reset || status < .inited else {
            return
        }
        
        self.logDebug("setup session", name, "...")
        
        // stop capturing if reset
        if reset {
            session.stopRunning()
            status = .inited
        }
        session.beginConfiguration()
        
        defer {
            session.commitConfiguration()
            // start capturing if reset
            if reset && !session.isRunning {
                session.startRunning()
                status = .started
            }
            fetchSettings()
            self.logDebug("setup session", name, "!")
        }
        
        if !session.canSetSessionPreset(settings.preset) {
            throw TnAppError.general(message: "Cannot set session preset: [\(settings.preset.rawValue)]")
        }
        session.sessionPreset = settings.preset
        
        // wide color
        session.automaticallyConfiguresCaptureDeviceForWideColor = settings.wideColor
        
        do {
            // add inputs
            try addInputs()
            
            // add outputs
            try addOutputs()

            // setup device
            try setupDevice(name: name, deviceLock: deviceLock, deviceHandler: deviceHandler)
            
            status = .inited
            
            logDebug("setup session", "!")
        } catch {
            status = .failed
            logError("setup session", "failed !")
            throw error
        }
    }
    
    private func resetSession(name: String, deviceLock: Bool = false, deviceHandler: DoDeviceHandler? = nil) throws {
        logDebug("reset session", name, "...")
        try setupSession(name: name, reset: true, deviceLock: deviceLock, deviceHandler: deviceHandler)
        logDebug("reset session", name, "!")
    }

    public func resetSession<TValue:  Equatable>(name: String, _ keyPath: WritableKeyPath<TnCameraSettings, TValue>, _ v: TValue) throws {
        guard settings[keyPath: keyPath] != v else { return }

        settings[keyPath: keyPath] = v
        // then reset the session
        try resetSession(name: name)
    }

    private func configSession(name: String, sessionLock: Bool = false, deviceLock: Bool = false, deviceHandler: DoDeviceHandler? = nil) throws {
        logDebug("config session", name, "...")
        
        defer {
            if sessionLock {
                session.commitConfiguration()
            }
            // start session
            if !session.isRunning {
                session.startRunning()
                status = .started
            }
            fetchSettings()
            logDebug("config session", name, "!")
        }
        // lock session
        if sessionLock {
            // stop session
            if session.isRunning {
                session.stopRunning()
                status = .inited
            }

            session.beginConfiguration()
        }
        // setup device
        try setupDevice(name: name, deviceLock: deviceLock, deviceHandler: deviceHandler)
    }
}


// MARK: public services
extension TnCameraService {
    public func startCapturing() async throws {
        guard await isAuthorized, !session.isRunning else { return }
        try setupSession(name: "startCapturing", reset: false)
        
        session.startRunning()
        status = .started
    }
    
    public func stopCapturing() {
        guard session.isRunning else { return }
        
        session.stopRunning()
        status = .inited
    }
    
    public func toggleCapturing() async throws {
        if session.isRunning {
            stopCapturing()
        } else {
            try await startCapturing()
        }
    }
    
    public func switchCamera() throws {
        guard session.isRunning else { return }
        
        settings.cameraPosition = settings.cameraPosition.toggle()
        // change cameratype if necessary
        forceValueInRange(&settings.cameraType, TnCameraDiscover.getAvailableDeviceTpes(for: settings.cameraPosition))
        
        // then reset the session
        try resetSession(name: "switchCamera")
    }
    
    public func setLivephoto(_ v: Bool) throws {
        guard settings.livephotoSupported && settings.livephoto != v else { return }
        
        try configSession(name: "setLivephoto", sessionLock: true) { [self] _, _ in
            photoOutput.isLivePhotoCaptureEnabled = photoOutput.isLivePhotoCaptureSupported && v
        }
    }
    
    public func setPreset(_ v: AVCaptureSession.Preset) throws {
        try resetSession(name: "setPreset", \.preset, v)
    }
    
    public func setCameraType(_ v: AVCaptureDevice.DeviceType) throws {
        try resetSession(name: "setCameraType", \.cameraType, v)
    }
    
    public func setWideColor(_ v: Bool) throws {
        try resetSession(name: "setWideColor", \.wideColor, v)
    }

    public func setDepth(_ v: Bool) throws {
        guard settings.depthSupported && settings.depth != v else { return }
        
        try configSession(name: "setDepth", sessionLock: true, deviceLock: true) { [self] _, device in
            photoOutput.isDepthDataDeliveryEnabled = v
            if v, let depthFormat = device.getDepthFormat(mediaSubTypes: [kCVPixelFormatType_DepthFloat32]) {
                device.activeDepthDataFormat = depthFormat
            }
        }
    }
    
    public func setPortrait(_ v: Bool) throws {
        guard settings.portraitSupported && settings.portrait != v else { return }
        
        try configSession(name: "setPortrait", sessionLock: true, deviceLock: true) { [self] _, device in
            photoOutput.isPortraitEffectsMatteDeliveryEnabled = v
        }
    }
    
    public func setHDR(_ v: TnTripleState) throws {
        guard settings.hdr != v else { return }

        try configSession(name: "setHDR", sessionLock: true, deviceLock: true) { _, device in
            device.automaticallyAdjustsVideoHDREnabled = v == .auto
            if v != .auto {
                device.isVideoHDREnabled = v.toBool()!
            }
        }
    }
    
    public func setPriority(_ v: AVCapturePhotoOutput.QualityPrioritization) throws {
        guard settings.priority != v else { return }
        settings.priority = v
    }
    
    public func setExposureMode(_ v: AVCaptureDevice.ExposureMode) throws {
        guard settings.exposureMode != v else { return }

        try configSession(name: "setExposureMode", sessionLock: false, deviceLock: true) { _, device in
            device.exposureMode = v
        }
    }

    public func setExposure(_ v: TnCameraExposureValue) throws {
        guard settings.exposureMode == .custom else { return }

        try configSession(name: "setExposure", sessionLock: false, deviceLock: true) { _, device in
            let defaultISO = device.iso /*AVCaptureDevice.currentISO*/
            let defaultDuration = device.exposureDuration /*AVCaptureDevice.currentExposureDuration*/
            
            device.setExposureModeCustom(
                duration: v.duration == nil ? defaultDuration : CMTime(seconds: v.duration!, preferredTimescale: device.exposureDuration.timescale),
                iso: v.iso ?? defaultISO
            )
        }
    }

    public func setFocusMode(_ v: AVCaptureDevice.FocusMode) throws {
        guard settings.focusMode != v else { return }

        try configSession(name: "setFocusMode", sessionLock: false, deviceLock: true) { _, device in
            device.focusMode = v
        }
    }

    public func setZoomFactor(_ v: TnCameraZoomFactorValue) throws {        
        try configSession(name: "setZoomFactor", deviceLock: true) { [self] _, device in
            var newV = v.value * settings.zoomMainFactor
            if v.adjust {
                newV = getValueInRange(device.videoZoomFactor + v.value - 1, device.minAvailableVideoZoomFactor, device.maxAvailableVideoZoomFactor)
            }
            guard settings.zoomRange.contains(v.value) && newV != device.videoZoomFactor else { return }
            
            device.ramp(toVideoZoomFactor: newV, withRate: v.withRate * Float(settings.zoomMainFactor))
        }
    }

    public func setFlash(_ v: AVCaptureDevice.FlashMode) {
        guard settings.flashSupported && settings.flashMode != v else { return }
        settings.flashMode = v
    }

    public func setTransport(_ v: TnCameraTransportValue) {
        if let scale = v.scale {
            settings.transportScale = scale
        }
        if let imageCompressQuality = v.compressQuality {
            settings.transportCompressQuality = imageCompressQuality
        }
        if let imageContinuous = v.continuous {
            settings.transportContinuous = imageContinuous
        }
    }
}

// MARK: captureImage
extension TnCameraService {
    private func createPhotoSettings() -> AVCapturePhotoSettings {
        var p: AVCapturePhotoSettings!
        // Capture HEVC photos when supported
        if photoOutput.availablePhotoCodecTypes.contains(.hevc) {
            p = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
        } else {
            p = .init()
        }
        p.flashMode = settings.flashMode
        
        // Sets the preview thumbnail pixel format
        if let previewPhotoPixelFormatType = p.availablePreviewPhotoPixelFormatTypes.first {
            p.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPhotoPixelFormatType]
        }
        // maxPhotoDimensions
        if #available(iOS 16.0, *) {
            p.maxPhotoDimensions = photoOutput.maxPhotoDimensions
        }
        // priority
        p.photoQualityPrioritization = settings.priority
        
        // depth
        if settings.depthSupported {
            p.isDepthDataDeliveryEnabled = settings.depth
            p.embedsDepthDataInPhoto = settings.depth
        }
        
        // portrait
        if settings.portraitSupported {
            p.isPortraitEffectsMatteDeliveryEnabled = settings.portrait
            p.embedsPortraitEffectsMatteInPhoto = settings.portrait
        }
        
        // live photo
        if photoOutput.isLivePhotoCaptureEnabled {
            p.livePhotoMovieFileURL = URL(fileURLWithPath: NSTemporaryDirectory() + UUID().uuidString).appendingPathExtension(for: .quickTimeMovie)
        }
        
        return p
    }
    
    private func captureImage() async throws -> TnCameraPhotoOutput {
        defer {
            captureDelegate = nil
        }
        return try await withCheckedThrowingContinuation { continuation in
            photoOutput.orientation = .fromUI(DeviceMotionOrientationListener.shared.orientation)

            let p = createPhotoSettings()
            captureDelegate = TnCameraCaptureDelegate(continuation: continuation)
            photoOutput.capturePhoto(with: p, delegate: captureDelegate!)
        }
    }
    
    public func captureImage(_ v: TnCameraCaptureValue) async throws -> TnCameraPhotoOutput {
        try await captureImage()
//        for _ in 0..<v.count {
//            let output = try await captureImage()
//            completion?(output)
//        }
    }
}

extension TnCameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    private func setImage(_ ciImage: CIImage) async {
        self.currentCiImage = ciImage
    }
    
    nonisolated public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        Task {
            await setImage(CIImage(cvImageBuffer: pixelBuffer))
        }
    }
}

//// MARK: CameraManagerProtocol
//extension TnCameraService: TnCameraProtocol {
//    public var currentCiImagePublisher: Published<CIImage?>.Publisher {
//        $currentCiImage
//    }
//    
//    public var settingsPublisher: Published<TnCameraSettings>.Publisher {
//        $settings
//    }
//    
//    public var statusPublisher: Published<TnCameraStatus>.Publisher {
//        $status
//    }
//    
//}


