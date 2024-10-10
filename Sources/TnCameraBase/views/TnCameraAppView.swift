//
//  File.swift
//  
//
//  Created by Thinh Nguyen on 9/13/24.
//

import Foundation
import SwiftUI
import TnIosBase
import CoreData

// MARK: TnCameraAppView
public struct TnCameraAppView: View, TnLoggable {
    @State private var showToolbar = false
    @State private var toolbarType: TnCameraToolbarViewType = .main
    @State private var settings: TnCameraSettings = .init()
    @State private var status: TnCameraStatus = .none
    @State private var capturedImage: UIImage? = nil

    private let serverMode: Bool
    private let bleInfo: TnNetworkBleInfo
    private let transportingInfo: TnNetworkTransportingInfo

    public init(serverMode: Bool, bleInfo: TnNetworkBleInfo, transportingInfo: TnNetworkTransportingInfo) {
        self.serverMode = serverMode
        self.bleInfo = bleInfo
        self.transportingInfo = transportingInfo
        logDebug("inited")
    }
    
    public var body: some View {
        ZStack {
            // background
            Rectangle()
                .fill(.black)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            if status == .started {
                // preview
                TnCameraPreviewViewMetal(imagePublisher: { await cameraProxy.currentCiImagePublisher })
                    .onTapGesture {
                        withAnimation {
                            showToolbar.toggle()
                        }
                    }
                // toolbar
                TnCameraToolbarView(
                    showToolbar: $showToolbar,
                    toolbarType: $toolbarType,
                    settings: $settings,
                    capturedImage: $capturedImage
                )
            }
        }
        .background(.black)
        .overlay(alignment: .top) {
            TnCameraToolbarTopView()
        }
        .onAppear {
            logDebug("appear")
        }
        .task {
            try? await tnDoCatchAsync(name: "TnCameraAppView setup") {
                if serverMode {
                    if #available(iOS 17.0, *) {
//                        let settingsPair = try await TnCodablePersistenceController.shared.fetch(defaultObject: { TnCameraSettings.init() })
                        let settingsPair = try TnCodablePersistenceController.shared.fetch(defaultObject: { TnCameraSettings.init() })
                        globalCameraSettingsID = settingsPair.objectID
                        let cameraService = TnCameraService(settings: settingsPair.object)
                        let cameraProxy = TnCameraProxyServerAsync(
                            cameraService,
                            bleInfo: bleInfo,
                            transportingInfo: transportingInfo
                        )
                        cameraProxy.bleDelegate = cameraProxy
                        globalCameraProxy = cameraProxy
                    }
                } else {
                    let cameraProxy = TnCameraProxyClient(
                        bleInfo: bleInfo,
                        transportingInfo: transportingInfo
                    )
                    cameraProxy.bleDelegate = cameraProxy
                    globalCameraProxy = cameraProxy
                }
                globalCameraProxy.delegate = self
                globalCameraProxy.setup()
            }
        }
    }
}

extension TnCameraAppView: TnCameraDelegate {
    public func tnCamera(captured: TnCameraPhotoOutput) {
        capturedImage = UIImage(data: captured.photoData)
    }
    
    public func tnCamera(status: TnCameraStatus) {
        guard self.status != status else { return }
        
        DispatchQueue.main.async {
            logDebug("status changed", status)
            self.status = status

            if serverMode {
                cameraProxy.send(.getSettingsResponse, TnCameraSettingsValue(settings: settings, status: status))
            }
        }
    }
    
    public func tnCamera(settings: TnCameraSettings) {
        DispatchQueue.main.async {
            logDebug("settings changed")
            self.settings = settings

            if serverMode {
                logDebug("send settings")
                cameraProxy.send(.getSettingsResponse, TnCameraSettingsValue(settings: settings, status: status))

                Task {
                    logDebug("save settings")
                    try? await TnCodablePersistenceController.shared.update(
                        objectID: globalCameraSettingsID,
                        object: settings
                    )
                }
            }
        }
    }
}

