//
//  File.swift
//  
//
//  Created by Thinh Nguyen on 9/13/24.
//

import Foundation
import SwiftUI
import TnIosBase

public struct TnCameraAppViewModelFactory {
    private init() {}
    
    struct ServerDelegate: TnCameraViewModelDelegate {
        let cameraProxy: TnCameraProxyServerAsync
        
        func onChanged(status: TnCameraBase.TnCameraStatus) {
        }
        
        func onChanged(settings: TnCameraBase.TnCameraSettings) {
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
    
    public static func createServerAsyncModel(delegate: TnCameraViewModelDelegate?, EOM: String?, MTU: Int?, encoder: TnEncoder, decoder: TnDecoder) -> (proxy: TnCameraProxyProtocol, model: TnCameraViewModel) {
        
        Task {
            if let settingsPair = try? await TnCodablePersistenceController.shared.fetch(defaultObject: { TnCameraSettings.init() }) {
                globalCameraSettingsID = settingsPair.objectID
                Task {
                    await TnCameraService.shared.setSettings(settings: settingsPair.object)
                }
            }
        }
        
        let cameraProxy = TnCameraProxyServerAsync(TnCameraService.shared, bleInfo: TnCameraProxyServiceInfo.getBle(), transportingInfo: TnCameraProxyServiceInfo.getTransporting(EOM: EOM, MTU: MTU, encoder: encoder, decoder: decoder))
        let cameraModel = TnCameraViewModel()

        cameraModel.delegate = delegate ?? ServerDelegate(cameraProxy: cameraProxy)
        cameraProxy.bleDelegate = cameraProxy
        return (cameraProxy, cameraModel)
    }

    public static func createClientModel(delegate: TnCameraViewModelDelegate?, EOM: String?, MTU: Int?, encoder: TnEncoder, decoder: TnDecoder) -> (proxy: TnCameraProxyProtocol, model: TnCameraViewModel) {
        let cameraProxy = TnCameraProxyClient(bleInfo: TnCameraProxyServiceInfo.getBle(), transportingInfo: TnCameraProxyServiceInfo.getTransporting(EOM: EOM, MTU: MTU, encoder: encoder, decoder: decoder))
        let cameraModel = TnCameraViewModel()
        
        cameraModel.delegate = delegate ?? ClientDelegate(cameraManager: cameraProxy)
        cameraProxy.bleDelegate = cameraProxy
        return (cameraProxy, cameraModel)
    }
}
