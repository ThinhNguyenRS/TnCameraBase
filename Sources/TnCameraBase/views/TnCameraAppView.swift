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
    public let LOG_NAME = "TnCameraAppView.\(TCameraManager.Type.self)"
    @ViewBuilder var bottom: () -> TBottom
    @EnvironmentObject var appModel: TnCameraAppViewModel<TCameraManager>
    @EnvironmentObject var cameraModel: TnCameraViewModel
    
//    let cameraService: TnCameraService = .init()

    public init(_ type: TCameraManager.Type, @ViewBuilder bottom: @escaping () -> TBottom) {
        self.bottom = bottom
        logDebug("inited")
    }
}

extension TnCameraAppView: View {
    public var body: some View {
        ZStack {
            if cameraModel.status == .started {
                // preview
//                TnCameraPreviewViewMetal(imagePublisher: { await cameraService.$currentCiImage })
//                    .onTapGesture {
//                        withAnimation {
//                            appModel.showToolbar.toggle()
//                        }
//                    }
                TnCameraPreviewViewMetal().setImagePublisher(imagePublisher: { await appModel.cameraManager.currentCiImagePublisher })
                    .onTapGesture {
                        withAnimation {
                            appModel.showToolbar.toggle()
                        }
                    }

                // bottom toolbar
                if appModel.showToolbar {
                    VStack(alignment: .leading) {
                        Spacer()
                        TnCameraToolbarMiscView(cameraManager: appModel.cameraManager)
                        TnCameraToolbarMainView(cameraManager: appModel.cameraManager, bottom: bottom())
                    }
                }
            }
        }
        .onAppear {
            appModel.setup()
        }
    }
}
