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
        
        func onChanged(settings: TnCameraBase.TnCameraSettings, status: TnCameraBase.TnCameraStatus) {
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
        
        func onChanged(settings: TnCameraBase.TnCameraSettings, status: TnCameraBase.TnCameraStatus) {
        }
        
        func onVolumeButton() {
        }
    }
    
    public static func createServerAsyncModel(delegate: TnCameraViewModelDelegate? = nil, EOM: String? = nil, MTU: Int? = nil) -> TnCameraAppViewModel<TnCameraProxyServerAsync> {
        let appModel: TnCameraAppViewModel = .init(
            cameraProxy: TnCameraProxyServerAsync(TnCameraService.shared, networkInfo: TnCameraProxyServiceInfo.getInstance(EOM: EOM, MTU: MTU)),
            cameraModel: TnCameraViewModel()
        )
        appModel.cameraModel.delegate = delegate ?? ServerDelegate(cameraProxy: appModel.cameraProxy)
        appModel.cameraProxy.bleDelegate = appModel.cameraProxy
        appModel.cameraProxy.captureCompletion = { output in
            let uiImage = UIImage(data: output.photoData)
            DispatchQueue.main.async {
                withAnimation {
                    appModel.cameraModel.capturedImage = uiImage
                }
                appModel.cameraProxy.sendImage()
            }
        }
        return appModel
    }

    public static func createClientModel(delegate: TnCameraViewModelDelegate? = nil, EOM: String? = nil, MTU: Int? = nil) -> TnCameraAppViewModel<TnCameraProxyClient> {
        let appModel: TnCameraAppViewModel = .init(
            cameraProxy: TnCameraProxyClient(networkInfo: TnCameraProxyServiceInfo.getInstance(EOM: EOM, MTU: MTU)),
            cameraModel: TnCameraViewModel()
        )
        appModel.cameraModel.delegate = delegate ?? ClientDelegate(cameraManager: appModel.cameraProxy)
        appModel.cameraProxy.bleDelegate = appModel.cameraProxy
        return appModel
    }
}
