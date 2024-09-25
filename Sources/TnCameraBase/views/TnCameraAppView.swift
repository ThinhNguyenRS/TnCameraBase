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

    public init(cameraModel: TnCameraViewModel, @ViewBuilder bottom: @escaping () -> TBottom) {
        self.cameraModel = cameraModel
        self.bottom = bottom
        logDebug("inited")
    }
}

extension TnCameraAppView: View {
    public var body: some View {
        ZStack {
            // preview
            preview
                .onAppear {
                    preview.setImagePublisher(imagePublisher: { await cameraModel.cameraProxy.currentCiImagePublisher })
                }
                .onTapGesture {
                    withAnimation {
                        cameraModel.showToolbar.toggle()
                    }
                }

            // bottom toolbar
            TnCameraToolbarView(cameraModel: cameraModel, bottom: bottom)
        }
        .onAppear {
            cameraModel.setup()
        }
    }
}

struct TnCameraToolbarView<TBottom: View>: View {
    @ObservedObject var cameraModel: TnCameraViewModel
    @ViewBuilder var bottom: () -> TBottom

    var body: some View {
        // bottom toolbar
        if cameraModel.showToolbar {
            VStack(alignment: .leading) {
                Spacer()
                TnCameraToolbarMiscView(cameraModel: cameraModel, cameraProxy: cameraModel.cameraProxy)
                TnCameraToolbarMainView(cameraModel: cameraModel, cameraProxy: cameraModel.cameraProxy, bottom: bottom())
            }
        }
    }
}
