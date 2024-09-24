//
//  File.swift
//  
//
//  Created by Thinh Nguyen on 9/13/24.
//

import Foundation
import SwiftUI
import TnIosBase

public struct TnCameraAppView<TCameraProxy: TnCameraProxyProtocol, TBottom: View>: TnLoggable {
    @ViewBuilder var bottom: () -> TBottom
    @ObservedObject var appModel: TnCameraAppViewModel<TCameraProxy>
    @ObservedObject var cameraModel: TnCameraViewModel

    let preview = TnCameraPreviewViewMetal()

    let toolbarMainView: TnCameraToolbarMainView<TBottom, TCameraProxy>
    let toolbarMiscView: TnCameraToolbarMiscView<TCameraProxy>

    public init(appModel: TnCameraAppViewModel<TCameraProxy>, @ViewBuilder bottom: @escaping () -> TBottom) {
        self.appModel = appModel
        self.cameraModel = appModel.cameraModel
        self.bottom = bottom

        self.toolbarMiscView = TnCameraToolbarMiscView(cameraModel: appModel.cameraModel, cameraProxy: appModel.cameraProxy)
        self.toolbarMainView = TnCameraToolbarMainView(cameraModel: appModel.cameraModel, cameraProxy: appModel.cameraProxy, bottom: bottom())
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
                        toolbarMainView
                    }
                }
            }
            
        }
        .onAppear {
            preview.setImagePublisher(imagePublisher: { await appModel.cameraProxy.currentCiImagePublisher })
            appModel.setup()
        }
    }
}
