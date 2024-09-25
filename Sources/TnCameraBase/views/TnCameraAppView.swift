//
//  File.swift
//  
//
//  Created by Thinh Nguyen on 9/13/24.
//

import Foundation
import SwiftUI
import TnIosBase

public struct TnCameraAppView<TBottom: View>: TnLoggable {
    @ViewBuilder var bottom: () -> TBottom
    @ObservedObject var cameraModel: TnCameraViewModel

    let preview = TnCameraPreviewViewMetal()

    let toolbarMainView: TnCameraToolbarMainView<TBottom>
    let toolbarMiscView: TnCameraToolbarMiscView

    public init(cameraModel: TnCameraViewModel, @ViewBuilder bottom: @escaping () -> TBottom) {
        self.cameraModel = cameraModel
        self.bottom = bottom

        self.toolbarMiscView = TnCameraToolbarMiscView(cameraModel: cameraModel, cameraProxy: cameraModel.cameraProxy)
        self.toolbarMainView = TnCameraToolbarMainView(cameraModel: cameraModel, cameraProxy: cameraModel.cameraProxy, bottom: bottom())
        logDebug("inited")
    }
}

extension TnCameraAppView: View {
    public var body: some View {
        ZStack {
            if cameraModel.status == .started {
                // preview
                preview
                    .onAppear {
                        preview.setImagePublisher(imagePublisher: { await cameraModel.cameraProxy.currentCiImagePublisher })
                        cameraModel.setup()
                    }
                    .onTapGesture {
                        withAnimation {
                            cameraModel.showToolbar.toggle()
                        }
                    }

                // bottom toolbar
                if cameraModel.showToolbar {
                    VStack(alignment: .leading) {
                        Spacer()
                        toolbarMiscView
                        toolbarMainView
                    }
                }
            }
        }
    }
}
