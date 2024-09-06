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
    func onChanged(settings: TnCameraSettings, status: TnCameraStatus)
    func onVolumeButton()
}

public class TnCameraViewModel: NSObject, ObservableObject, TnLoggable {
    public let LOG_NAME = "CameraViewModel"
    @Published public var status: TnCameraStatus = .none
    @Published public var settings: TnCameraSettings = .init()
    @Published public var toolbarType: TnCameraToolbarViewType = .none

    @Published public var orientation: UIDeviceOrientation = .unknown
    @Published public var orientationAngle: Angle = .zero
    
    private var cancelables: Set<AnyCancellable> = []
    public var delegate: TnCameraViewModelDelegate? = nil
    
    public override init() {
        super.init()
        logDebug("inited")
    }
    
    public func listen(manager: TnCameraProtocol, withOrientation: Bool = true) {
        let motionOrientation: DeviceMotionOrientationListener = .shared
        manager.statusPublisher
            .onReceive(debounceMs: 10, cancelables: &cancelables) { [self] v in
                withAnimation {
                    status = v
                    logDebug("status changed", v)
                }
                delegate?.onChanged(settings: settings, status: status)
            }

        manager.settingsPublisher
            .onReceive(debounceMs: 10, cancelables: &cancelables) { [self] v in
                withAnimation {
                    settings = v
                    logDebug("settings changed")
                }
                delegate?.onChanged(settings: settings, status: status)
            }

        if withOrientation {
            motionOrientation.$orientation
                .onReceive(debounceMs: 10, cancelables: &cancelables) { [self] _ in
                    withAnimation {
                        orientation = motionOrientation.orientation
                        orientationAngle = motionOrientation.angle
                        self.logDebug("orientation changed")
                    }
                }
        }
        
        do {
            try AVAudioSession.sharedInstance().setActive(true)
            AVAudioSession.sharedInstance().publisher(for: \.outputVolume)
                .sink(receiveValue: { [self] v in
                    delegate?.onVolumeButton()
                })
                .store(in: &cancelables)
        } catch {
            logError("Cannot listen volume button", error.localizedDescription)
        }
    }
}
