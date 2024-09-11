//
//  AppViewModel.swift
//  tCamera
//
//  Created by Thinh Nguyen on 8/22/24.
//

import Foundation
import SwiftUI
import TnIosBase

public struct TnCameraAppViewProxyClient: TnCameraAppViewProtocol {
    public typealias TAppViewModel = TnCameraAppViewProxyClientModel
    @StateObject public var appModel: TAppViewModel
    
    public var bottom: Optional<some View> {
        HStack {
            tnCircleButton(imageName: "photo.artframe", radius: 50) {
                cameraManager.send(.getImage)
            }
        }
    }
    public var showToolbar: State<Bool> = .init(initialValue: true)
}

extension TnCameraAppViewProxyClient {
    public static func getInstance(cameraManager: TnCameraProxyClient, cameraModel: TnCameraViewModel) -> Self {
        Self.init(appModel: TnCameraAppViewProxyClientModel(cameraManager: cameraManager, cameraModel: cameraModel))
    }
}
