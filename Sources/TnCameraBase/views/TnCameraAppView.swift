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
    @State private var status: TnCameraStatus = .none
    @State private var capturedImage: UIImage? = nil
    
    private let serverMode: Bool
    private let bleInfo: TnNetworkBleInfo
    private let transportingInfo: TnNetworkTransportingInfo

    public init(serverMode: Bool, EOM: String? = nil, MTU: Int? = nil, encoder: TnEncoder, decoder: TnDecoder) {
        self.serverMode = serverMode
        bleInfo = TnCameraProxyServiceInfo.getBle()
        transportingInfo = TnCameraProxyServiceInfo.getTransporting(EOM: EOM, MTU: MTU, encoder: encoder, decoder: decoder)
        logDebug("inited")
    }
    
    public var body: some View {
        Group {
            ZStack {
                // background
                Rectangle()
                    .fill(.black)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onTapGesture(count: 2) {
                        cameraProxy.startCapturing()
                    }

                if status == .started {
                    // preview
                    TnCameraPreviewViewMetal(imagePublisher: { await cameraProxy.currentCiImagePublisher })
                        .onTapGesture(count: 3) {
                            cameraProxy.stopCapturing()
                        }
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
            }
            .onAppear {
                logDebug("appear")
            }
        }
        .task {
            try? await tnDoCatchAsync(name: "TnCameraAppView setup") {
                if serverMode {
                    let settingsPair = try await TnCodablePersistenceController.shared.fetch(defaultObject: { TnCameraSettings.init() })
                    globalCameraSettingsID = settingsPair.objectID
                    await TnCameraService.shared.setSettings(settings: settingsPair.object)
                    let cameraProxy = TnCameraProxyServerAsync(
                        TnCameraService.shared,
                        bleInfo: bleInfo,
                        transportingInfo: transportingInfo
                    )
                    cameraProxy.bleDelegate = cameraProxy
                    globalCameraProxy = cameraProxy
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
        }
        if serverMode {
            cameraProxy.send(.getSettingsResponse, TnCameraSettingsValue(settings: settings, status: status))
        }
    }
    
    public func tnCamera(settings: TnCameraSettings) {
        DispatchQueue.main.async {
            logDebug("settings changed")
            self.settings = settings
        }
        if serverMode {
            cameraProxy.send(.getSettingsResponse, TnCameraSettingsValue(settings: settings, status: status))
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

extension View {
    func onSwipe(left: @escaping () -> Void, right: @escaping () -> Void, up: @escaping () -> Void, down: @escaping () -> Void) -> some View {
        self.gesture(DragGesture(minimumDistance: 3.0, coordinateSpace: .local)
            .onEnded { value in
                switch(value.translation.width, value.translation.height) {
                case (...0, -30...30): // left
                    left()
                    break
                case (0..., -30...30): // right
                    right()
                    break
                case (-100...100, ...0): // up
                    up()
                case (-100...100, 0...): // down
                    down()
                default:
                    break
                }
            }
        )
    }
}
