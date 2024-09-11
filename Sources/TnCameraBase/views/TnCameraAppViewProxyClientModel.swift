//
//  AppViewModelProxyClient.swift
//  TnCameraMaster
//
//  Created by Thinh Nguyen on 9/6/24.
//

import Foundation

public class TnCameraAppViewProxyClientModel: TnCameraAppViewModelDefault<TnCameraProxyClient>, TnCameraViewModelDelegate {
    public override init(cameraManager: TnCameraProxyClient, cameraModel: TnCameraViewModel) {
        super.init(cameraManager: cameraManager, cameraModel: cameraModel)
        LOG_NAME = "TnCameraAppViewProxyClientModel"
        logDebug("inited")
    }

    public func onChanged(settings: TnCameraSettings, status: TnCameraStatus) {
    }
    
    public func onVolumeButton() {
        cameraManager.captureImage()
    }
    
    public override func setup() {
        cameraModel.delegate = self
        cameraManager.bleDelegate = cameraManager
        super.setup(withOrientation: true)
    }
}
