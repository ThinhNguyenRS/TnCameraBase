//
//  MainView+new.swift
//  tCamera
//
//  Created by Thinh Nguyen on 7/22/24.
//

import Foundation
import SwiftUI
import Combine
import TnIosBase

public struct TnCameraToolbarMainView<TBottom: View>: View, TnLoggable {
    @State private var capturedImage: UIImage? = nil

    @ViewBuilder private let bottom: () -> TBottom?
    @Binding private var toolbarType: TnCameraToolbarViewType
    @Binding var settings: TnCameraSettings

    init(bottom: @escaping () -> TBottom?, toolbarType: Binding<TnCameraToolbarViewType>, settings: Binding<TnCameraSettings>) {
        self.bottom = bottom
        self._toolbarType = toolbarType
        self._settings = settings
        
        logDebug("inited")
    }

    public var body: some View {
        HStack {
            if let capturedImage {
                Image(uiImage: capturedImage)
                    .tnMakeScalable()
                    .frame(width: 80, height: 80)
            }

            Spacer()
            circleButtonRotation(imageName: settings.cameraPosition.imageName) {
                cameraProxy.switchCamera()
            }

            Spacer()
            getSettingsButton(type: .zoom, text: settings.zoomFactor.toString("%0.2f"))

            if let bottomView = bottom() {
                Spacer()
                bottomView
            }

            // capture
            Spacer()
            circleButtonRotation(imageName: "camera", radius: 90, backColor: .white, imageColor: .black) {
                cameraProxy.captureImage()
            }

            // settings
            Spacer()
            getSettingsButton(type: .misc, imageName: "ellipsis")

            Spacer()
        }
        .task {
//            cameraProxy.captureCompletion = { output in
//                let uiImage = UIImage(data: output.photoData)
//                DispatchQueue.main.async {
//                    withAnimation {
//                        capturedImage = uiImage
//                    }
////                    cameraProxy.sendImage()
//                }
//            }
        }
    }
}

extension TnCameraToolbarMainView {
    public func getSettingsButton(type: TnCameraToolbarViewType, text: String) -> some View {
        circleButtonRotation(text: text) {
            withAnimation {
                if toolbarType != type {
                    toolbarType = type
                } else {
                    toolbarType = .none
                }
            }
        }
    }

    public func getSettingsButton(type: TnCameraToolbarViewType, imageName: String) -> some View {
        circleButtonRotation(imageName: imageName) {
            withAnimation {
                if toolbarType != type {
                    toolbarType = type
                } else {
                    toolbarType = .none
                }
            }
        }
    }
}

