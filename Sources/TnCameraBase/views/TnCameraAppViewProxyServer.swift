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
    
    @StateObject public var appModel: TAppViewModel
    public var bottom: Optional<some View> {
        nil as EmptyView?
    }
    public var showToolbar: State<Bool> = .init(initialValue: true)
}

extension TnCameraAppViewProxyServer {
    public static func getInstance(cameraManager: TnCameraProxyServer, cameraModel: TnCameraViewModel) -> Self {
        Self.init(appModel: TnCameraAppViewProxyServerModel(cameraManager: cameraManager, cameraModel: cameraModel))
    }
}
