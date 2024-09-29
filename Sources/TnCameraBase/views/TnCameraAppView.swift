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
    @StateObject var cameraModel: TnCameraViewModel
    @ViewBuilder private let bottom: () -> TBottom?
    
    @State private var showToolbar = false
    @State private var status: TnCameraStatus = .none
    @State var settings: TnCameraSettings = .init()

    public init(serverMode: Bool, bottom: @escaping () -> TBottom?, EOM: String? = nil, MTU: Int = 512*1024) {
        var model: (proxy: TnCameraProxyProtocol, model: TnCameraViewModel)
        if serverMode {
            model = TnCameraAppViewModelFactory.createServerAsyncModel(EOM: EOM, MTU: MTU)
        } else {
            model = TnCameraAppViewModelFactory.createClientModel(EOM: EOM, MTU: MTU)
        }
        globalCameraProxy = model.proxy
        
        self._cameraModel = StateObject(wrappedValue: model.model)
        self.bottom = bottom
        logDebug("inited")
    }
    
    public var body: some View {
        Group {
//            if status == .started {
                ZStack {
                    // preview
                    TnCameraPreviewViewMetal(imagePublisher: { await cameraProxy.currentCiImagePublisher })
                        .onTapGesture {
                            withAnimation {
                                showToolbar.toggle()
                            }
                        }

                    // bottom toolbar
                    TnCameraToolbarView(bottom: bottom, showToolbar: $showToolbar, settings: $settings)
                }
                .onAppear {
                    logDebug("appear")
                }
//            }
        }
        .environmentObject(cameraModel)
        .task {
            cameraProxy.setup()
            await self.listen()
        }
    }
    
    func listen() async {
        // listen changes here
        await cameraProxy.statusPublisher
            .onReceive { [self] v in
                if status != v {
                    logDebug("status changed", v)
                    withAnimation {
                        status = v
                    }
//                        delegate?.onChanged(status: v)
                }
            }
        
        await cameraProxy.settingsPublisher
            .onReceive { [self] v in
                if status == .started {
                    logDebug("settings changed")
                    withAnimation {
                            settings = v
                    }
    //                    delegate?.onChanged(settings: v)
                }
            }
    }
}

extension TnCameraAppView where TBottom == EmptyView {
    public init(serverMode: Bool) {
        self.init(serverMode: serverMode, bottom: { nil })
    }
}

struct TnCameraToolbarView<TBottom: View>: View, TnLoggable {
    @ViewBuilder private let bottom: () -> TBottom?
    
    @Binding private var showToolbar: Bool
    @State private var toolbarType: TnCameraToolbarViewType = .main
    @Binding var settings: TnCameraSettings

    init(bottom: @escaping () -> TBottom?, showToolbar: Binding<Bool>, settings: Binding<TnCameraSettings>) {
        self.bottom = bottom
        self._showToolbar = showToolbar
        self._settings = settings
        
        logDebug("inited")
    }
    
    var body: some View {
        // bottom toolbar
        if showToolbar {
            VStack(alignment: .leading) {
                Spacer()
//                TestToolbar(settings: $settings)
                TnCameraToolbarMiscView(toolbarType: $toolbarType, settings: $settings)
                TnCameraToolbarMainView(bottom: bottom, toolbarType: $toolbarType, settings: $settings)
            }
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
