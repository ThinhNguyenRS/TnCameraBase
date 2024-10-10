//
//  TnCameraAppViewMaster.swift
//  TnCameraBase
//
//  Created by Thinh Nguyen on 10/10/24.
//

import Foundation
import SwiftUI
import CoreData
import TnIosBase

// MARK: TnCameraAppViewMaster
@available(iOS 17.0, *)
public struct TnCameraAppViewMaster: View, TnLoggable {
    @State private var cameraSettingsID: NSManagedObjectID = .init()

    public init(EOM: String? = nil, MTU: Int? = nil, encoder: TnEncoder, decoder: TnDecoder) {
        let cameraProxy = TnCameraProxyServerAsync(
            TnCameraService.shared,
            bleInfo: TnCameraProxyServiceInfo.getBle(),
            transportingInfo: TnCameraProxyServiceInfo.getTransporting(EOM: EOM, MTU: MTU, encoder: encoder, decoder: decoder)
        )
        cameraProxy.bleDelegate = cameraProxy
        globalCameraProxy = cameraProxy
        logDebug("inited")
    }
    
    public var body: some View {
        TnCameraAppViewInternal(delegate: self)
            .task {
                try? await tnDoCatchAsync(name: "TnCameraAppViewMaster setup") {
                    logDebug("setup ...")

                    let settingsPair = try await TnCodablePersistenceController.shared.fetch(defaultObject: { TnCameraSettings.init() })
                    cameraSettingsID = settingsPair.objectID
                    await TnCameraService.shared.setSettings(settings: settingsPair.object)
                    
                    globalCameraProxy.setup()

                    logDebug("setup !")
                }
            }
    }
}

@available(iOS 17.0, *)
extension TnCameraAppViewMaster: TnCameraAppViewDelegate {
    func onChanged(status: TnCameraStatus, settings: TnCameraSettings) {
        logDebug("send settings")
        cameraProxy.send(.getSettingsResponse, TnCameraSettingsValue(settings: settings, status: status))
        
//        Task {
//            logDebug("save settings")
//            try? await TnCodablePersistenceController.shared.update(
//                objectID: cameraSettingsID,
//                object: settings
//            )
//        }
    }
}
