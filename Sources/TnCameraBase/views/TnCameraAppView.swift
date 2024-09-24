//
//  File.swift
//  
//
//  Created by Thinh Nguyen on 9/13/24.
//

import Foundation
import SwiftUI
import TnIosBase

public struct TnCameraAppView<TCameraManager: TnCameraProxyProtocol, TBottom: View>: TnLoggable {
    @ViewBuilder var bottom: () -> TBottom
    @ObservedObject var appModel: TnCameraAppViewModel<TCameraManager>
    @ObservedObject var cameraModel: TnCameraViewModel

    let preview = TnCameraPreviewViewMetal()

    let toolbarMainView: TnCameraToolbarMainView<TBottom, TCameraManager>
    let toolbarMiscView: TnCameraToolbarMiscView<TCameraManager>

    public init(appModel: TnCameraAppViewModel<TCameraManager>, @ViewBuilder bottom: @escaping () -> TBottom) {
        self.appModel = appModel
        self.cameraModel = appModel.cameraModel
        self.bottom = bottom

        self.toolbarMiscView = TnCameraToolbarMiscView(cameraModel: appModel.cameraModel, cameraManager: appModel.cameraManager)
        self.toolbarMainView = TnCameraToolbarMainView(cameraModel: appModel.cameraModel, cameraManager: appModel.cameraManager, bottom: bottom())
        logDebug("inited")
    }
}

extension TnCameraAppView: View {
    public var body: some View {
        ZStack {
            if cameraModel.status == .started {
                // preview
                preview
                    .onTapGesture {
                        withAnimation {
                            appModel.showToolbar.toggle()
                        }
                    }

                // bottom toolbar
                if appModel.showToolbar {
                    VStack(alignment: .leading) {
                        Spacer()
                        toolbarMiscView
                            .animation(.bouncy, value: appModel.cameraModel.toolbarType)
                        toolbarMainView
                    }
//                    .transition(.moveAndFade)
                    .animation(.bouncy, value: appModel.showToolbar)
                }
            }
            
        }
        .onAppear {
            preview.setImagePublisher(imagePublisher: { await appModel.cameraManager.currentCiImagePublisher })
            appModel.setup()
        }
    }
}
