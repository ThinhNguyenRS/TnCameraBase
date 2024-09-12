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
    public var showToolbar: State<Bool> = .init(initialValue: true)
    
    //    public var appModelState: StateObject<TAppViewModel>
    //    public var appModel: TAppViewModel {
    //        appModelState.wrappedValue
    //    }
    //
    //    public init(appModel: TAppViewModel) {
    //        self.appModelState = .init(wrappedValue: appModel)
    //        logDebug("inited")
    //    }

    @StateObject public var appModel: TAppViewModel
    public init(appModel: StateObject<TAppViewModel>) {
        self._appModel = appModel
        logDebug("inited")
    }
}
