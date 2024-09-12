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
        
    public var appModelState: StateObject<TAppViewModel>
    public init(appModel: StateObject<TAppViewModel>) {
        self.appModelState = appModel
        logDebug("inited")
    }
}
