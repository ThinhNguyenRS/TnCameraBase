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
    public var bottom: Optional<some View> {
        HStack {
            tnCircleButton(imageName: "photo.artframe", radius: 50) {
                cameraManager.send(.getImage)
            }
        }
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

