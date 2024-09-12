//
//  AppViewProxyServer.swift
//  TnCameraMaster
//
//  Created by Thinh Nguyen on 9/6/24.
//

import Foundation
import SwiftUI
import TnIosBase

public struct TnCameraAppViewProxyServer: TnCameraAppViewProtocol, TnLoggable {
    public typealias TAppViewModel = TnCameraAppViewProxyServerModel
    public let LOG_NAME = "TnCameraAppViewProxyServer"
    
    public var bottom: Optional<some View> {
        nil as EmptyView?
    }
    
    public var showToolbarState: State<Bool> = .init(initialValue: true)
    
    public var appModelState: StateObject<TAppViewModel>
    public init(appModel: StateObject<TAppViewModel>) {
        self.appModelState = appModel
        logDebug("inited")
    }
        
//    public var body: some View {
//        ZStack {
//            // preview
//            TnCameraPreviewViewMetal(imagePublisher: appModel.wrappedValue.cameraManager.currentCiImagePublisher)
//                .onTapGesture {
//                    withAnimation {
//                        showToolbar.wrappedValue.toggle()
//                    }
//                }
//            
//            // bottom toolbar
//            if showToolbar.wrappedValue {
//                VStack(alignment: .leading) {
//                    Spacer()
//                    TnCameraToolbarMiscView(cameraManager: appModel.wrappedValue.cameraManager)
//                    TnCameraToolbarMainView(cameraManager: appModel.wrappedValue.cameraManager, bottom: bottom)
//                }
//            }
////            if appModel.cameraManager.status == .started {
////                // preview
////                TnCameraPreviewViewMetal(imagePublisher: appModel.cameraManager.currentCiImagePublisher)
////                    .onTapGesture {
////                        withAnimation {
////                            showToolbar.toggle()
////                        }
////                    }
////                
////                // bottom toolbar
////                if showToolbar {
////                    VStack(alignment: .leading) {
////                        Spacer()
////                        TnCameraToolbarMiscView(cameraManager: appModel.cameraManager)
////                        TnCameraToolbarMainView(cameraManager: appModel.cameraManager, bottom: bottom)
////                    }
////                }
////            }
//        }
//        .onAppear {
//            appModel.wrappedValue.setup()
//        }
//    }
}
