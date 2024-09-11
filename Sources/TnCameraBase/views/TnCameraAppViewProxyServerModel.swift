//
//  AppViewModelProxyServer.swift
//  TnCameraMaster
//
//  Created by Thinh Nguyen on 9/6/24.
//

import Foundation
import SwiftUI

public class TnCameraAppViewProxyServerModel: TnCameraAppViewModelDefault<TnCameraProxyServer>, TnCameraViewModelDelegate {
    public func onVolumeButton() {
        cameraManager.captureImage()
    }
    
    public func onChanged(settings: TnCameraSettings, status: TnCameraStatus) {
        cameraManager.send(
            .getSettingsResponse,
            TnCameraGetSettingsValue(settings: cameraManager.settings, status: status)
        )
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [self] in
            cameraManager.sendImage()
        }
    }
    
    public override func setup() {
        cameraModel.delegate = self
        cameraManager.bleDelegate = cameraManager
        cameraManager.captureCompletion = { [self] capturedImage in
            withAnimation {
                cameraModel.capturedImage = capturedImage
            }
            cameraManager.sendImage()
        }
        super.setup(withOrientation: true)
    }
}
