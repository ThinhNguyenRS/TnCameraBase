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

    public init(bottom: @escaping () -> TBottom?) {
        self.bottom = bottom
        logDebug("inited")
    }
    
    public var body: some View {
        Group {
            if status == .started {
                ZStack {
                    // preview
                    TnCameraPreviewViewMetal(imagePublisher: { await cameraModel.cameraProxy.currentCiImagePublisher })
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
            let cameraProxy = cameraModel.cameraProxy
            cameraProxy.setup()
            // listen changes here
            await cameraProxy.statusPublisher
                .onReceive(cancellables: &cameraCancellables) { [self] v in
                    if status != v {
                        logDebug("status changed", v)
                        withAnimation {
                            status = v
                        }
//                        delegate?.onChanged(status: v)
                    }
                }
            
            await cameraProxy.settingsPublisher
                .onReceive(cancellables: &cameraCancellables) { [self] v in
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
    public init() {
        self.init(bottom: { nil })
    }
}

struct TnCameraToolbarView<TBottom: View>: View, TnLoggable {
    @EnvironmentObject var cameraModel: TnCameraViewModel
    @ViewBuilder private let bottom: () -> TBottom?
    
    @Binding var showToolbar: Bool
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
