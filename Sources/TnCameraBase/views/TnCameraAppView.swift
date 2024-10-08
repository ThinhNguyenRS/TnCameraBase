//
//  File.swift
//  
//
//  Created by Thinh Nguyen on 9/13/24.
//

import Foundation
import SwiftUI
import TnIosBase




public struct TnCameraAppView: View, TnLoggable {
    @State private var showToolbar = false
    @State private var toolbarType: TnCameraToolbarViewType = .main
    @State private var settings: TnCameraSettings = .init()
    @State private var capturedImage: UIImage? = nil
    
    private let serverMode: Bool

    public init(serverMode: Bool, EOM: String? = nil, MTU: Int? = nil, encoder: TnEncoder, decoder: TnDecoder) {
        self.serverMode = serverMode
        
        var model: (proxy: TnCameraProxyProtocol, model: TnCameraViewModel)
        if serverMode {
            model = TnCameraAppViewModelFactory.createServerAsyncModel(delegate: nil, EOM: EOM, MTU: MTU, encoder: encoder, decoder: decoder)
        } else {
            model = TnCameraAppViewModelFactory.createClientModel(delegate: nil, EOM: EOM, MTU: MTU, encoder: encoder, decoder: decoder)
        }
        globalCameraProxy = model.proxy

        logDebug("inited")
    }
    
    public var body: some View {
        Group {
            ZStack {
                // preview
                TnCameraPreviewViewMetal(imagePublisher: { await cameraProxy.currentCiImagePublisher })
                    .onTapGesture(count: 2) {
                        cameraProxy.captureImage()
                    }
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
            .onAppear {
                logDebug("appear")
            }
        }
        .task {
            globalCameraProxy.delegate = self
            globalCameraProxy.setup()
        }
    }
}

extension TnCameraAppView: TnCameraDelegate {
    public func tnCamera(captured: TnCameraPhotoOutput) {
        capturedImage = UIImage(data: captured.photoData)
    }
    
    public func tnCamera(status: TnCameraStatus) {
    }
    
    public func tnCamera(settings: TnCameraSettings) {
        DispatchQueue.main.async {
            logDebug("settings changed")
            self.settings = settings
        }
        if serverMode {
            Task {
                logDebug("save settings")
                try? await TnCodablePersistenceController.shared.update(
                    objectID: globalCameraSettingsID,
                    object: await TnCameraService.shared.settings
                )
            }
        }
    }
}

struct TnCameraToolbarView: View, TnLoggable {
    @Binding private var showToolbar: Bool
    @Binding private var toolbarType: TnCameraToolbarViewType
    @Binding private var settings: TnCameraSettings
    @Binding private var capturedImage: UIImage?
    
    init(showToolbar: Binding<Bool>, toolbarType: Binding<TnCameraToolbarViewType>, settings: Binding<TnCameraSettings>, capturedImage: Binding<UIImage?>) {
        self._showToolbar = showToolbar
        self._toolbarType = toolbarType
        self._settings = settings
        self._capturedImage = capturedImage
        
        logDebug("inited")
    }
    
    var body: some View {
        // bottom toolbar
        if showToolbar {
            VStack(alignment: .leading) {
                Spacer()

                // variant toolbar
                if toolbarType == .zoom {
                    TnCameraToolbarZoomView(settings: $settings)
                        .padding(.all, 12)
                        .background(Color.appleAsparagus.opacity(0.75))
                        .cornerRadius(8)
                }
                else if toolbarType == .misc {
                    TnCameraToolbarMiscView(settings: $settings)
                }

                // main toolbar
                TnCameraToolbarMainView(toolbarType: $toolbarType, settings: $settings, capturedImage: $capturedImage)
            }
        }
    }
}
