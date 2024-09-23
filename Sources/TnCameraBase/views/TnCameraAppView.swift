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
    @EnvironmentObject var appModel: TnCameraAppViewModel<TCameraManager>
    @EnvironmentObject var cameraModel: TnCameraViewModel
    
    let preview = TnCameraPreviewViewMetal()
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
                        TnCameraToolbarMiscView(cameraManager: appModel.cameraManager)
                        TnCameraToolbarMainView(cameraManager: appModel.cameraManager, bottom: bottom())
                    }
                }
            }
        }
        .onAppear {
            preview.setImagePublisher(imagePublisher: { await appModel.cameraManager.currentCiImagePublisher })
            appModel.setup()
        }
    }
}
