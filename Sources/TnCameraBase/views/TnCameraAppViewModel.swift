//
//  File.swift
//  
//
//  Created by Thinh Nguyen on 9/13/24.
//

import Foundation
import SwiftUI
import TnIosBase

public class TnCameraAppViewModel<TCameraManager: TnCameraProxyProtocol>: NSObject, ObservableObject, TnLoggable {
    public let LOG_NAME = "TnCameraAppViewModel.\(TCameraManager.Type.self)"
    
    @Published public var cameraManager: TCameraManager
    @Published public var cameraModel: TnCameraViewModel
    @Published public var showToolbar: Bool = true
    let listenOrientation: Bool
    
    public init(
        cameraManager: TCameraManager,
        cameraModel: TnCameraViewModel,
        listenOrientation: Bool = true
    ) {
        self.cameraManager = cameraManager
        self.cameraModel = cameraModel
        self.listenOrientation = listenOrientation
        super.init()
        
        logDebug("inited")
    }
    
    public func setup() {
        cameraModel.listen(manager: cameraManager, withOrientation: listenOrientation)
        cameraManager.setup()
    }
}

public struct TnCameraAppView<TCameraManager: TnCameraProxyProtocol, TBottom: View>: TnLoggable {
    public let LOG_NAME = "TnCameraAppView.\(TCameraManager.Type.self)"
    var appModelState: StateObject<TnCameraAppViewModel<TCameraManager>>
    
    @ViewBuilder var bottom: () -> TBottom?
    
    public init(appModel: StateObject<TnCameraAppViewModel<TCameraManager>>, @ViewBuilder bottom: @escaping () -> TBottom?) {
        self.appModelState = appModel
        self.bottom = bottom
        logDebug("inited")
    }
}

extension TnCameraAppView {
    public var appModel: TnCameraAppViewModel<TCameraManager> {
        appModelState.wrappedValue
    }
    
    public var cameraModel: TnCameraViewModel {
        appModelState.wrappedValue.cameraModel
    }
    
    public var cameraManager: TCameraManager {
        appModelState.wrappedValue.cameraManager
    }
}

extension TnCameraAppView: View {
    public var body: some View {
        ZStack {
            // preview
            TnCameraPreviewViewMetal(imagePublisher: cameraManager.currentCiImagePublisher)
                .onTapGesture {
                    withAnimation {
                        appModel.showToolbar.toggle()
                    }
                }

            // bottom toolbar
            if appModel.showToolbar {
                VStack(alignment: .leading) {
                    Spacer()
                    TnCameraToolbarMiscView(cameraManager: cameraManager)
                    TnCameraToolbarMainView(cameraManager: cameraManager, bottom: bottom())
                }
            }
        }
        .environmentObject(cameraModel)
        .onAppear {
            appModel.setup()
        }
    }
}
