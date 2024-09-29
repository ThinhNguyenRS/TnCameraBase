//
//  File.swift
//  
//
//  Created by Thinh Nguyen on 9/13/24.
//

import Foundation
import SwiftUI
import TnIosBase


public struct TnCameraAppView<TBottom: View>: View, TnLoggable {
    @ViewBuilder private let bottom: () -> TBottom?
    
    @State private var showToolbar = false
    @State private var toolbarType: TnCameraToolbarViewType = .main
    @State private var settings: TnCameraSettings = .init()
    @State private var capturedImage: UIImage? = nil

    public init(serverMode: Bool, bottom: @escaping () -> TBottom?, EOM: String? = nil, MTU: Int = 512*1024) {
        var model: (proxy: TnCameraProxyProtocol, model: TnCameraViewModel)
        if serverMode {
            model = TnCameraAppViewModelFactory.createServerAsyncModel(EOM: EOM, MTU: MTU)
        } else {
            model = TnCameraAppViewModelFactory.createClientModel(EOM: EOM, MTU: MTU)
        }
        globalCameraProxy = model.proxy

        self.bottom = bottom
        logDebug("inited")
    }
    
    public var body: some View {
        Group {
            ZStack {
                // preview
                TnCameraPreviewViewMetal(imagePublisher: { await cameraProxy.currentCiImagePublisher })
                    .onTapGesture {
                        withAnimation {
                            showToolbar.toggle()
                        }
                    }

                // bottom toolbar
                if showToolbar {
                    VStack(alignment: .leading) {
                        Spacer()

                        // variant toolbar
                        Group {
                            switch toolbarType {
                            case .zoom:
                                TnCameraToolbarZoomView(settings: $settings)
                            case .misc:
                                TnCameraToolbarMiscView(settings: $settings)
                            default:
                                nil as EmptyView?
                            }
                        }
                        .padding(.all, 12)
                        .background(Color.appleAsparagus.opacity(0.75))
                        .cornerRadius(8)

                        // main toolbar
                        TnCameraToolbarMainView(bottom: bottom, toolbarType: $toolbarType, settings: $settings, capturedImage: $capturedImage)
                    }
                }
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

extension TnCameraAppView where TBottom == EmptyView {
    public init(serverMode: Bool) {
        self.init(serverMode: serverMode, bottom: { nil })
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
    }
}

struct TestToolbar: View, TnLoggable {
    @State private var value: Double = 0
    @Binding var settings: TnCameraSettings

//    init(cameraModel: TnCameraViewModel) {
//        self._cameraModel = StateObject(wrappedValue: cameraModel)
//    }
    
    init(settings: Binding<TnCameraSettings>) {
        _settings = settings
        logDebug("inited")
    }

    var body: some View {
        tnSliderViewVert(
            value: $settings.zoomFactor,
            label: "Test slider",
            bounds: 0.5...4,
            step: 0.05,
            formatter: getNumberFormatter("%.2f")
        )
    }
}

var globalCameraProxy: TnCameraProxyProtocol!
extension View {
    var cameraProxy: TnCameraProxyProtocol {
        get {
            globalCameraProxy
        }
        set {
            globalCameraProxy = newValue
        }
    }
}
