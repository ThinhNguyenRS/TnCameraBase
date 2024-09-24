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
    
    public init(appModel: TnCameraAppViewModel<TCameraManager>, @ViewBuilder bottom: @escaping () -> TBottom) {
        self.appModel = appModel
        self.cameraModel = appModel.cameraModel
        self.bottom = bottom
        logDebug("inited")
    }
}

extension TnCameraAppView: View {
    public var body: some View {
        ZStack {
//            // preview
//            preview
//                .onTapGesture {
//                    withAnimation {
//                        appModel.showToolbar.toggle()
//                    }
//                }
//
//            // bottom toolbar
//            if appModel.showToolbar {
//                VStack(alignment: .leading) {
//                    Spacer()
//                    TnCameraToolbarMiscView(cameraModel: appModel.cameraModel, cameraManager: appModel.cameraManager)
//                    TnCameraToolbarMainView(cameraModel: appModel.cameraModel, cameraManager: appModel.cameraManager, bottom: bottom())
//                }
//                .transition(.move(edge: .bottom))
//            }
            
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
                        TnCameraToolbarMiscView(cameraModel: cameraModel, cameraManager: appModel.cameraManager)
                        TnCameraToolbarMainView(cameraModel: cameraModel, cameraManager: appModel.cameraManager, bottom: bottom())
                    }
                    .transition(.move(edge: .bottom))
                }
            }
            
        }
        .onAppear {
            preview.setImagePublisher(imagePublisher: { await appModel.cameraManager.currentCiImagePublisher })
            appModel.setup()
        }
    }
}
