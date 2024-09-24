//
//  MainView+new.swift
//  tCamera
//
//  Created by Thinh Nguyen on 7/22/24.
//

import Foundation
import SwiftUI
import Combine

public struct TnCameraToolbarMainView<TBottom: View, TCameraManager: TnCameraProxyProtocol>: View, TnCameraViewProtocol {
    @ObservedObject public var cameraModel: TnCameraViewModel
    let cameraManager: TCameraManager
    let bottom: TBottom?
    
    init(cameraModel: TnCameraViewModel, cameraManager: TCameraManager, bottom: TBottom?) {
        self.cameraModel = cameraModel
        self.cameraManager = cameraManager
        self.bottom = bottom
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
                    cameraManager.switchCamera()
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
                    cameraManager.captureImage()
                }

                // settings
                Spacer()
                getSettingsButton(type: .misc, imageName: "ellipsis")

                Spacer()
            }
        }
    }
}
