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
    public var showToolbar: State<Bool> = .init(initialValue: true)
    
    public var appModelState: StateObject<TAppViewModel>
    public var appModel: TAppViewModel {
        appModelState.wrappedValue
    }
    
    public init(appModel: TAppViewModel) {
        self.appModelState = .init(wrappedValue: appModel)
    }
}
