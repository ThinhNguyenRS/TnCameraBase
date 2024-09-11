//
//  AppViewProxyServer.swift
//  TnCameraMaster
//
//  Created by Thinh Nguyen on 9/6/24.
//

import Foundation
import SwiftUI

public struct TnCameraAppViewProxyServer: TnCameraAppViewProtocol {
    public typealias TAppViewModel = TnCameraAppViewProxyServerModel
    public var bottom: Optional<some View> {
        nil as EmptyView?
    }
    
//    @StateObject public var appModel: TAppViewModel
    public var showToolbar: State<Bool> = .init(initialValue: true)
    
    public var appModelState: StateObject<TAppViewModel>
    public var appModel: TAppViewModel {
        appModelState.wrappedValue
    }
    
    public init(appModel: StateObject<TAppViewModel>) {
        self.appModelState = appModel
    }
}

//extension TnCameraAppViewProxyServer {
//    public static func getInstance(cameraManager: TnCameraProxyServer, cameraModel: TnCameraViewModel) -> Self {
//        TnCameraAppViewProxyServer(appModel: TnCameraAppViewProxyServerModel(cameraManager: cameraManager, cameraModel: cameraModel))
//    }
//    
//    public static func getInstance(appModel: TnCameraAppViewProxyServerModel) -> Self {
//        TnCameraAppViewProxyServer(appModel: appModel)
//    }
//}
