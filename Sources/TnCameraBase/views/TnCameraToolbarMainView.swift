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

public struct TnCameraToolbarMainView<TBottom: View>: View, TnCameraViewProtocol, TnLoggable {
    @EnvironmentObject public var cameraModel: TnCameraViewModel
    @ViewBuilder private let bottom: () -> TBottom?

    var cameraProxy: TnCameraProxyProtocol {
        cameraModel.cameraProxy
    }

    init(bottom: @escaping () -> TBottom?) {
        self.bottom = bottom
        logDebug("inited")
    }

    public var body: some View {
        HStack {
            if let capturedImage = cameraModel.capturedImage {
                Image(uiImage: capturedImage)
                    .tnMakeScalable()
                    .frame(width: 80, height: 80)
            }

            Spacer()
            circleButtonRotation(imageName: cameraModel.settings.cameraPosition.imageName) {
                cameraProxy.switchCamera()
            }

            Spacer()
            getSettingsButton(type: .zoom, text: cameraModel.settings.zoomFactor.toString("%0.2f"))

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
    }
}
