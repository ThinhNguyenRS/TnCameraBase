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
        let cameraProxy: TnCameraProxyServerAsync
        
        func onChanged(status: TnCameraBase.TnCameraStatus) {
//            cameraProxy.send(
//                .getSettingsResponse,
//                TnCameraSettingsValue(settings: settings, status: status)
//            )
//            cameraProxy.sendImage()
        }
        
        func onChanged(settings: TnCameraBase.TnCameraSettings) {
//            cameraProxy.send(
//                .getSettingsResponse,
//                TnCameraSettingsValue(settings: settings, status: status)
//            )
//            cameraProxy.sendImage()
        }

        func onVolumeButton() {
        }
    }
    
    struct ClientDelegate: TnCameraViewModelDelegate {
        let cameraManager: TnCameraProxyClient
        
        func onChanged(status: TnCameraBase.TnCameraStatus) {
        }
        
        func onChanged(settings: TnCameraBase.TnCameraSettings) {
        }

        func onVolumeButton() {
        }
    }
    
    public static func createServerAsyncModel(delegate: TnCameraViewModelDelegate? = nil, EOM: String? = nil, MTU: Int? = nil) -> (proxy: TnCameraProxyProtocol, model: TnCameraViewModel) {
        let cameraProxy = TnCameraProxyServerAsync(TnCameraService.shared, networkInfo: TnCameraProxyServiceInfo.getInstance(EOM: EOM, MTU: MTU))
        let cameraModel = TnCameraViewModel()

        cameraModel.delegate = delegate ?? ServerDelegate(cameraProxy: cameraProxy)
        cameraProxy.bleDelegate = cameraProxy
        return (cameraProxy, cameraModel)
    }

    public static func createClientModel(delegate: TnCameraViewModelDelegate? = nil, EOM: String? = nil, MTU: Int? = nil) -> (proxy: TnCameraProxyProtocol, model: TnCameraViewModel) {
        let cameraProxy = TnCameraProxyClient(networkInfo: TnCameraProxyServiceInfo.getInstance(EOM: EOM, MTU: MTU))
        let cameraModel = TnCameraViewModel()
        
        cameraModel.delegate = delegate ?? ClientDelegate(cameraManager: cameraProxy)
        cameraProxy.bleDelegate = cameraProxy
        return (cameraProxy, cameraModel)
    }
}
