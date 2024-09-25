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
    //    @ObservedObject var cameraModel: TnCameraViewModel
    @EnvironmentObject var cameraModel: TnCameraViewModel
    
    let preview = TnCameraPreviewViewMetal()
    
//    public init(cameraModel: TnCameraViewModel, @ViewBuilder bottom: @escaping () -> TBottom) {
//        self.cameraModel = cameraModel
//        self.bottom = bottom
//        logDebug("inited")
//    }
    
    public init(@ViewBuilder bottom: @escaping () -> TBottom) {
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
            TnCameraToolbarView(bottom: bottom)
        }
        .onAppear {
            cameraModel.setup()
        }
    }
}

struct TnCameraToolbarView<TBottom: View>: View, TnLoggable {
    @EnvironmentObject var cameraModel: TnCameraViewModel
    @ViewBuilder var bottom: () -> TBottom

    init(bottom: @escaping () -> TBottom) {
        self.bottom = bottom
        logDebug("inited")
    }
    
    var body: some View {
        // bottom toolbar
        if cameraModel.showToolbar {
            VStack(alignment: .leading) {
                Spacer()
                TnCameraToolbarMiscView(cameraProxy: cameraModel.cameraProxy)
                TnCameraToolbarMainView(cameraProxy: cameraModel.cameraProxy, bottom: bottom())
            }
        }
    }
}
