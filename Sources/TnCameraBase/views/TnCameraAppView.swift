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
    @EnvironmentObject var cameraModel: TnCameraViewModel
    @ViewBuilder private let bottom: () -> TBottom?
    
    @State private var showToolbar = false
    @State private var status: TnCameraStatus = .none

    public init(cameraProxy: TnCameraProxyProtocol, bottom: @escaping () -> TBottom?) {
        globalCameraProxy = cameraProxy
        self.bottom = bottom
        logDebug("inited")
    }
    
    public var body: some View {
        Group {
            if status == .started {
                ZStack {
                    // preview
                    TnCameraPreviewViewMetal(imagePublisher: { await cameraProxy.currentCiImagePublisher })
                        .onTapGesture {
                            withAnimation {
                                showToolbar.toggle()
                            }
                        }

                    // bottom toolbar
                    TnCameraToolbarView(bottom: bottom, showToolbar: $showToolbar)
                }
                .onAppear {
                    logDebug("appear")
                }
            }
        }
        .task {
            cameraProxy.setup()
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
                    logDebug("settings changed")
                    withAnimation {
//                        settings = v
                    }
//                    delegate?.onChanged(settings: v)
                }
        }
    }
}

extension TnCameraAppView where TBottom == EmptyView {
    public init(cameraProxy: TnCameraProxyProtocol) {
        self.init(cameraProxy: cameraProxy, bottom: { nil })
    }
}

struct TnCameraToolbarView<TBottom: View>: View, TnLoggable {
    @EnvironmentObject var cameraModel: TnCameraViewModel
    @ViewBuilder private let bottom: () -> TBottom?
    
    @Binding private var showToolbar: Bool
    @State private var toolbarType: TnCameraToolbarViewType = .main

    init(bottom: @escaping () -> TBottom?, showToolbar: Binding<Bool>) {
        self.bottom = bottom
        self._showToolbar = showToolbar
        logDebug("inited")
    }
    
    var body: some View {
        // bottom toolbar
        if showToolbar {
            VStack(alignment: .leading) {
                Spacer()
                TnCameraToolbarMiscView(toolbarType: $toolbarType)
                TnCameraToolbarMainView(bottom: bottom, toolbarType: $toolbarType)
            }
        }
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
