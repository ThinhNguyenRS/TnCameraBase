//
//  AppViewProxyServer.swift
//  TnCameraMaster
//
//  Created by Thinh Nguyen on 9/6/24.
//

import Foundation
import SwiftUI
import TnCameraBase

public struct TnCameraAppViewProxyServer: TnCameraAppViewProtocol {
    public typealias TAppViewModel = TnCameraAppViewProxyServerModel
    
    @StateObject public var appModel: TAppViewModel
    public var bottom: Optional<some View> {
        nil as EmptyView?
    }
    public var showToolbar: State<Bool> = .init(initialValue: true)
}
