//
//  AppViewModel.swift
//  tCamera
//
//  Created by Thinh Nguyen on 8/22/24.
//

import Foundation
import SwiftUI
import TnIosBase

public struct TnCameraAppViewProxyClient: TnCameraAppViewProtocol, TnLoggable {
    public let LOG_NAME = "TnCameraAppViewProxyClient"
    
    public typealias TAppViewModel = TnCameraAppViewProxyClientModel
    public var bottom: Optional<some View> {
        HStack {
            tnCircleButton(imageName: "photo.artframe", radius: 50) {
                cameraManager.send(.getImage)
            }
        }
    }
    public var showToolbar: State<Bool> = .init(initialValue: true)
    public var appModel: StateObject<TAppViewModel>

    public init(appModel: StateObject<TAppViewModel>) {
        self.appModel = appModel
        logDebug("inited")
    }
}

