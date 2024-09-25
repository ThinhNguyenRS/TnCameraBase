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
    @ObservedObject public var cameraModel: TnCameraViewModel
    let cameraProxy: TnCameraProxyProtocol
    let bottom: TBottom?
    
    init(cameraModel: TnCameraViewModel, cameraProxy: TnCameraProxyProtocol, bottom: TBottom?) {
        self.cameraModel = cameraModel
        self.cameraProxy = cameraProxy
        self.bottom = bottom
        logDebug("inited")
    }

    public var body: some View {
        HStack {
            if cameraModel.status == .started {
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

                if let bottom {
                    Spacer()
                    bottom
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
}
