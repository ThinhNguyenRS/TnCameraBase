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

// MARK: TnCameraAppViewDelegate
protocol TnCameraAppViewDelegate {
    func onChanged(status: TnCameraStatus, settings: TnCameraSettings)
}

// MARK: TnCameraAppViewInternal
struct TnCameraAppViewInternal: View, TnLoggable {
    @State private var showToolbar = false
    @State private var toolbarType: TnCameraToolbarViewType = .main
    @State private var settings: TnCameraSettings = .init()
    @State private var status: TnCameraStatus = .none
    @State private var capturedImage: UIImage? = nil
    
    private let delegate: TnCameraAppViewDelegate?
    
    init(delegate: TnCameraAppViewDelegate? = nil) {
        self.delegate = delegate
        globalCameraProxy.delegate = self
        logDebug("inited")
    }
    
    var body: some View {
        Group {
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
            .overlay(alignment: .top) {
                TnCameraToolbarTopView()
            }
            .onAppear {
                logDebug("appear")
            }
        }
//        .background(.black)
    }
}

extension TnCameraAppViewInternal: TnCameraDelegate {
    public func tnCamera(captured: TnCameraPhotoOutput) {
        capturedImage = UIImage(data: captured.photoData)
    }
    
    public func tnCamera(status: TnCameraStatus) {
        guard self.status != status else { return }
        
        DispatchQueue.main.async {
            logDebug("status changed", status)
            self.status = status
            delegate?.onChanged(status: status, settings: settings)
        }
    }
    
    public func tnCamera(settings: TnCameraSettings) {
        DispatchQueue.main.async {
            logDebug("settings changed")
            self.settings = settings
            delegate?.onChanged(status: status, settings: settings)
        }
    }
}

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

// MARK: TnCameraAppViewSlaver
public struct TnCameraAppViewSlaver: View, TnLoggable {
    public init(EOM: String? = nil, MTU: Int? = nil, encoder: TnEncoder, decoder: TnDecoder) {
        let cameraProxy = TnCameraProxyClient(
            bleInfo: TnCameraProxyServiceInfo.getBle(),
            transportingInfo: TnCameraProxyServiceInfo.getTransporting(EOM: EOM, MTU: MTU, encoder: encoder, decoder: decoder)
        )
        cameraProxy.bleDelegate = cameraProxy
        globalCameraProxy = cameraProxy
        globalCameraProxy.setup()
    }
    
    public var body: some View {
        TnCameraAppViewInternal(delegate: self)
    }
}

extension TnCameraAppViewSlaver: TnCameraAppViewDelegate {
    func onChanged(status: TnCameraStatus, settings: TnCameraSettings) {
    }
}


//public struct TnCameraAppView: View, TnLoggable {
//    @State private var showToolbar = false
//    @State private var toolbarType: TnCameraToolbarViewType = .main
//    @State private var settings: TnCameraSettings = .init()
//    @State private var status: TnCameraStatus = .none
//    @State private var capturedImage: UIImage? = nil
//    
//    private let serverMode: Bool
//    private let bleInfo: TnNetworkBleInfo
//    private let transportingInfo: TnNetworkTransportingInfo
//
//    public init(serverMode: Bool, EOM: String? = nil, MTU: Int? = nil, encoder: TnEncoder, decoder: TnDecoder) {
//        self.serverMode = serverMode
//        bleInfo = TnCameraProxyServiceInfo.getBle()
//        transportingInfo = TnCameraProxyServiceInfo.getTransporting(EOM: EOM, MTU: MTU, encoder: encoder, decoder: decoder)
//        logDebug("inited")
//    }
//    
//    public var body: some View {
//        Group {
//            ZStack {
//                // background
//                Rectangle()
//                    .fill(.black)
//                    .frame(maxWidth: .infinity, maxHeight: .infinity)
//
//                if status == .started {
//                    // preview
//                    TnCameraPreviewViewMetal(imagePublisher: { await cameraProxy.currentCiImagePublisher })
//                        .onTapGesture {
//                            withAnimation {
//                                showToolbar.toggle()
//                            }
//                        }
//                    // toolbar
//                    TnCameraToolbarView(
//                        showToolbar: $showToolbar,
//                        toolbarType: $toolbarType,
//                        settings: $settings,
//                        capturedImage: $capturedImage
//                    )
//                }
//            }
//            .overlay(alignment: .top) {
//                TnCameraToolbarTopView()
//            }
//            .onAppear {
//                logDebug("appear")
//            }
//        }
//        .task {
//            try? await tnDoCatchAsync(name: "TnCameraAppView setup") {
//                if serverMode {
//                    let settingsPair = try await TnCodablePersistenceController.shared.fetch(defaultObject: { TnCameraSettings.init() })
//                    globalCameraSettingsID = settingsPair.objectID
//                    await TnCameraService.shared.setSettings(settings: settingsPair.object)
//                    let cameraProxy = TnCameraProxyServerAsync(
//                        TnCameraService.shared,
//                        bleInfo: bleInfo,
//                        transportingInfo: transportingInfo
//                    )
//                    cameraProxy.bleDelegate = cameraProxy
//                    globalCameraProxy = cameraProxy
//                } else {
//                    let cameraProxy = TnCameraProxyClient(
//                        bleInfo: bleInfo,
//                        transportingInfo: transportingInfo
//                    )
//                    cameraProxy.bleDelegate = cameraProxy
//                    globalCameraProxy = cameraProxy
//                }
//                globalCameraProxy.delegate = self
//                globalCameraProxy.setup()
//            }
//        }
//    }
//}
//
//extension TnCameraAppView: TnCameraDelegate {
//    public func tnCamera(captured: TnCameraPhotoOutput) {
//        capturedImage = UIImage(data: captured.photoData)
//    }
//    
//    public func tnCamera(status: TnCameraStatus) {
//        guard self.status != status else { return }
//        
//        DispatchQueue.main.async {
//            logDebug("status changed", status)
//            self.status = status
//
//            if serverMode {
//                cameraProxy.send(.getSettingsResponse, TnCameraSettingsValue(settings: settings, status: status))
//            }
//        }
//    }
//    
//    public func tnCamera(settings: TnCameraSettings) {
//        DispatchQueue.main.async {
//            logDebug("settings changed")
//            self.settings = settings
//
//            if serverMode {
//                logDebug("send settings")
//                cameraProxy.send(.getSettingsResponse, TnCameraSettingsValue(settings: settings, status: status))
//
//                Task {
//                    logDebug("save settings")
//                    try? await TnCodablePersistenceController.shared.update(
//                        objectID: globalCameraSettingsID,
//                        object: settings
//                    )
//                }
//            }
//        }
//    }
//}
//
