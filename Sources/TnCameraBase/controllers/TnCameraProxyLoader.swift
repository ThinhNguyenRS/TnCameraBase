//
//  TnCameraProxyLoader.swift
//  TnCameraBase
//
//  Created by Thinh Nguyen on 10/10/24.
//

import Foundation
import TnIosBase
import CoreData

public struct TnCameraProxyParams {
    public let master: Bool
    public let cameraProxy: TnCameraProtocol
    public let cameraSettingsID: NSManagedObjectID?
    
    init(master: Bool, cameraProxy: TnCameraProtocol, cameraSettingsID: NSManagedObjectID?) {
        self.master = master
        self.cameraProxy = cameraProxy
        self.cameraSettingsID = cameraSettingsID
    }
}

public struct TnCameraProxyLoader: TnLoggable {
    public static let shared = TnCameraProxyLoader()
    private init() {}
    
    public func loadSlaver(bleInfo: TnNetworkBleInfo, transportingInfo: TnNetworkTransportingInfo, delegate: TnCameraDelegate) {
        logDebug("load slaver ...")
        let cameraProxy = TnCameraProxyClient(
            bleInfo: bleInfo,
            transportingInfo: transportingInfo
        )
        cameraProxy.bleDelegate = cameraProxy
        cameraProxy.delegate = delegate
        globalCamera = TnCameraProxyParams(master: false, cameraProxy: cameraProxy, cameraSettingsID: nil)
        logDebug("load slaver !")
    }
    
    @available(iOS 17.0, *)
    public func loadMaster(bleInfo: TnNetworkBleInfo, transportingInfo: TnNetworkTransportingInfo, delegate: TnCameraDelegate) throws {
        logDebug("load master ...")
        let settingsPair = try TnCodablePersistenceController.shared.fetch(defaultObject: { TnCameraSettings.init() })
        let cameraService = TnCameraService(settings: settingsPair.object)
        let cameraProxy = TnCameraProxyServer(
            cameraService,
            bleInfo: bleInfo,
            transportingInfo: transportingInfo
        )
        cameraProxy.bleDelegate = cameraProxy
        cameraProxy.delegate = delegate
        globalCamera = TnCameraProxyParams(master: true, cameraProxy: cameraProxy, cameraSettingsID: settingsPair.objectID)
        logDebug("load master !")
    }
    
    public func saveSettings(_ settings: TnCameraSettings) throws {
        if let settingsID = globalCamera.cameraSettingsID {
            Task {
                logDebug("save settings ...")
                try TnCodablePersistenceController.shared.update(
                    objectID: settingsID,
                    object: settings
                )
                logDebug("save settings !")
            }
        }
    }
    
    public func setupProxy() {
        globalCamera.cameraProxy.setup()
    }
}
