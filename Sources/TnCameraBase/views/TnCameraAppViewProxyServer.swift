//
//  AppViewProxyServer.swift
//  TnCameraMaster
//
//  Created by Thinh Nguyen on 9/6/24.
//

import Foundation
import SwiftUI
import TnIosBase

public struct TnCameraAppViewProxyServer: View, TnLoggable {
    public typealias TAppViewModel = TnCameraAppViewProxyServerModel
    public let LOG_NAME = "TnCameraAppViewProxyServer"
    
    public var bottom: Optional<some View> {
        nil as EmptyView?
    }
    
    @State var showToolbar = true
    
    @StateObject public var appModel: TAppViewModel
    public init(appModel: StateObject<TAppViewModel>) {
        self._appModel = appModel
        logDebug("inited")
    }
        
    public var body: some View {
        ZStack {
            if appModel.cameraManager.status == .started {
                // preview
                TnCameraPreviewViewMetal(imagePublisher: appModel.cameraManager.currentCiImagePublisher)
                    .onTapGesture {
                        withAnimation {
                            showToolbar.toggle()
                        }
                    }
                
                // bottom toolbar
                if showToolbar {
                    VStack(alignment: .leading) {
                        Spacer()
                        TnCameraToolbarMiscView(cameraManager: appModel.cameraManager)
                        TnCameraToolbarMainView(cameraManager: appModel.cameraManager, bottom: bottom)
                    }
                }
            }
        }
        .onAppear {
            appModel.setup()
        }
    }
}
