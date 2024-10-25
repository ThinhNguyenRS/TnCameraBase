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
    private let delegate: TnCameraDelegate?

    public init(master: Bool, bleInfo: TnNetworkBleInfo, transportingInfo: TnNetworkTransportingInfo, delegate: TnCameraDelegate? = nil) {
        self.master = master
        self.bleInfo = bleInfo
        self.transportingInfo = transportingInfo
        self.delegate = delegate
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
    public func tnCamera(_ cameraProxy: TnCameraProtocol, captured: TnCameraPhotoOutput) {
        DispatchQueue.main.async {
            capturedImage = UIImage(data: captured.photoData)
        }
        delegate?.tnCamera(cameraProxy, captured: captured)
    }
    
    public func tnCamera(_ cameraProxy: TnCameraProtocol, status: TnCameraStatus) {
        guard self.status != status else { return }
        
        DispatchQueue.main.async {
            logDebug("status changed", status)
            self.status = status
        }

        delegate?.tnCamera(cameraProxy, status: status)
    }
    
    public func tnCamera(_ cameraProxy: TnCameraProtocol, settings: TnCameraSettings) {
        DispatchQueue.main.async {
            logDebug("settings changed")
            self.settings = settings
        }
        
        if master {
            Task {
                try? TnCameraProxyLoader.shared.saveSettings(settings)
            }
        }

        delegate?.tnCamera(cameraProxy, settings: settings)
    }
    
    public func tnCamera(_ cameraProxy: TnCameraProtocol, output: CIImage?) {
        delegate?.tnCamera(cameraProxy, output: output)
    }
}
