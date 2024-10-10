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

    private let master: Bool
    private let bleInfo: TnNetworkBleInfo
    private let transportingInfo: TnNetworkTransportingInfo

    public init(master: Bool, bleInfo: TnNetworkBleInfo, transportingInfo: TnNetworkTransportingInfo) {
        self.master = master
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
            if master {
                if #available(iOS 17.0, *) {
                    try? TnCameraProxyLoader.shared.loadMaster(bleInfo: bleInfo, transportingInfo: transportingInfo, delegate: self)
                }
            } else {
                TnCameraProxyLoader.shared.loadSlaver(bleInfo: bleInfo, transportingInfo: transportingInfo, delegate: self)
            }
            TnCameraProxyLoader.shared.setupProxy()
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
        }

        if master {
            logDebug("send status")
            cameraProxy.send(.getSettingsResponse, TnCameraSettingsValue(settings: nil, status: status, network: nil))
        }
    }
    
    public func tnCamera(settings: TnCameraSettings) {
        DispatchQueue.main.async {
            logDebug("settings changed")
            self.settings = settings
        }

        if master {
            logDebug("send settings")
            cameraProxy.send(.getSettingsResponse, TnCameraSettingsValue(settings: settings, status: nil, network: nil))

            try? TnCameraProxyLoader.shared.saveSettings(settings)
        }
    }
}
