//
//  File.swift
//  
//
//  Created by Thinh Nguyen on 9/13/24.
//

import Foundation
import SwiftUI
import TnIosBase

public struct TnCameraAppView<TBottom: View>: View, TnLoggable {
    @EnvironmentObject var cameraModel: TnCameraViewModel
    
    @ViewBuilder private let bottom: () -> TBottom?
    
    public init(bottom: @escaping () -> TBottom?) {
        self.bottom = bottom
        logDebug("inited")
    }
    
    public var body: some View {
        ZStack {
            // preview
            TnCameraPreviewViewMetal(imagePublisher: { await cameraModel.cameraProxy.currentCiImagePublisher })
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

extension TnCameraAppView where TBottom == EmptyView {
    public init() {
        self.init(bottom: { nil })
    }
}

struct TnCameraToolbarView<TBottom: View>: View, TnLoggable {
    @EnvironmentObject var cameraModel: TnCameraViewModel
    @ViewBuilder private let bottom: () -> TBottom?

    init(bottom: @escaping () -> TBottom?) {
        self.bottom = bottom
        logDebug("inited")
    }
    
    var body: some View {
        // bottom toolbar
        if cameraModel.showToolbar {
            VStack(alignment: .leading) {
                Spacer()
                TnCameraToolbarMiscView()
                TnCameraToolbarMainView(bottom: bottom)
            }
        }
    }
}
