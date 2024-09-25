//
//  AppViewModel.swift
//  tCamera
//
//  Created by Thinh Nguyen on 8/7/24.
//

import Foundation
import SwiftUI
import Combine
import AVFAudio
import TnIosBase

public protocol TnCameraViewModelDelegate {
    func onChanged(settings: TnCameraSettings)
    func onChanged(status: TnCameraStatus)
    func onVolumeButton()
}

public class TnCameraViewModel: NSObject, ObservableObject, TnLoggable {
//    @Published public var status: TnCameraStatus = .none
//    @Published public var settings: TnCameraSettings = .init()
    
    @Published public var showToolbar: Bool = true
    @Published public var toolbarType: TnCameraToolbarViewType = .none
    @Published public var capturedImage: UIImage? = nil
    
    @Published public var orientation: UIDeviceOrientation = .unknown
    @Published public var orientationAngle: Angle = .zero
    
    public var delegate: TnCameraViewModelDelegate? = nil
    public private(set) var cameraProxy: TnCameraProxyProtocol

    public var status: TnCameraStatus {
        cameraProxy.status
    }

    public var settings: TnCameraSettings {
        get {
            cameraProxy.settings
        }
        set {
            cameraProxy.settings = newValue
        }
    }

    public init(cameraProxy: TnCameraProxyProtocol) {
        self.cameraProxy = cameraProxy
        super.init()
        
        logDebug("inited")
    }
    
    public func listen(withOrientation: Bool = true) {
        Task {
            await cameraProxy.statusPublisher
                .onReceive(cancellables: &cameraCancellables) { [self] v in
                    withAnimation {
//                        status = v
                        logDebug("status changed", v)
                    }
                    delegate?.onChanged(status: status)
                }
            
            await cameraProxy.settingsPublisher
                .onReceive(debounceMs: 500, cancellables: &cameraCancellables) { [self] v in
                    withAnimation {
//                        settings = v
                        logDebug("settings changed")
                    }
                    delegate?.onChanged(settings: settings)
                }
        }
        
        if withOrientation {
            let motionOrientation: DeviceMotionOrientationListener = .shared
            motionOrientation.$orientation
                .onReceive(cancellables: &cameraCancellables) { [self] _ in
                    withAnimation {
                        orientation = motionOrientation.orientation
                        orientationAngle = motionOrientation.angle
                        self.logDebug("orientation changed")
                    }
                }
        }
        
        //        do {
        //            let audio = AVAudioSession.sharedInstance()
        //            try audio.setActive(true)
        //            audio.publisher(for: \.outputVolume)
        //                .sink(receiveValue: { [self] v in
        //                    if audio.outputVolume != v {
        //                        delegate?.onVolumeButton()
        //                    }
        //                })
        //                .store(in: &cancelables)
        //        } catch {
        //            logError("Cannot listen volume button", error.localizedDescription)
        //        }
    }

    public func setup(withOrientation: Bool = true) {
        listen(withOrientation: true)
        cameraProxy.setup()
    }
}
