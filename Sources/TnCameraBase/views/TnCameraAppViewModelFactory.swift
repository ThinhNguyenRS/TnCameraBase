//
//  File.swift
//  
//
//  Created by Thinh Nguyen on 9/13/24.
//

import Foundation
import SwiftUI

public struct TnCameraAppViewModelFactory {
    private init() {}
    
    struct ServerDelegate: TnCameraViewModelDelegate {
        let cameraManager: TnCameraProxyServer
        
        func onChanged(settings: TnCameraBase.TnCameraSettings, status: TnCameraBase.TnCameraStatus) {
            cameraManager.send(
                .getSettingsResponse,
                TnCameraGetSettingsValue(settings: cameraManager.settings, status: status)
            )
        }
        
        func onVolumeButton() {
        }
    }
    
    struct ClientDelegate: TnCameraViewModelDelegate {
        let cameraManager: TnCameraProxyClient
        
        func onChanged(settings: TnCameraBase.TnCameraSettings, status: TnCameraBase.TnCameraStatus) {
        }
        
        func onVolumeButton() {
        }
    }
    
    public static func createServerModel(delegate: TnCameraViewModelDelegate? = nil) -> TnCameraAppViewModel<TnCameraProxyServer> {
        let appModel: TnCameraAppViewModel = .init(
            cameraManager: TnCameraProxyServer(TnCameraLocal.shared, networkInfo: TnCameraProxyServiceInfo.shared),
            cameraModel: TnCameraViewModel()
        )
        appModel.cameraModel.delegate = delegate ?? ServerDelegate(cameraManager: appModel.cameraManager)
        appModel.cameraManager.bleDelegate = appModel.cameraManager
        appModel.cameraManager.captureCompletion = { capturedImage in
            DispatchQueue.main.async {
                withAnimation {
                    appModel.cameraModel.capturedImage = capturedImage
                }
                appModel.cameraManager.sendImage()
            }
        }
        return appModel
    }
    
    public static func createClientModel(delegate: TnCameraViewModelDelegate? = nil) -> TnCameraAppViewModel<TnCameraProxyClient> {
        let appModel: TnCameraAppViewModel = .init(
            cameraManager: TnCameraProxyClient(networkInfo: TnCameraProxyServiceInfo.shared),
            cameraModel: TnCameraViewModel()
        )
        appModel.cameraModel.delegate = delegate ?? ClientDelegate(cameraManager: appModel.cameraManager)
        appModel.cameraManager.bleDelegate = appModel.cameraManager
        return appModel
    }
}
