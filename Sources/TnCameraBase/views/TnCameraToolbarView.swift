//
//  AppToolbarView.swift
//  tCamera
//
//  Created by Thinh Nguyen on 8/7/24.
//

import SwiftUI

public struct TnCameraToolbarView<TBottom: View, TCameraManager: TnCameraProtocol>: View, TnCameraViewProtocol {
    @EnvironmentObject public var cameraModel: TnCameraViewModel
    let cameraManager: TCameraManager
    let bottom: TBottom?

    public var body: some View {
        VStack {
            Spacer()            
            if cameraModel.status == .started {
                TnCameraSettingsToolbarVariantView(cameraManager: cameraManager)
            }
            TnCameraToolbarMainView(cameraManager: cameraManager, bottom: bottom)
        }
    }
}
