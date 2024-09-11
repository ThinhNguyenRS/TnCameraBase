//
//  AppViewProtocol.swift
//  TnCameraMaster
//
//  Created by Thinh Nguyen on 9/6/24.
//

import Foundation
import SwiftUI

public protocol TnCameraAppViewProtocol: View {
    associatedtype TAppViewModel: TnCameraAppViewModelProtocol
    associatedtype TBottom: View
    
    var appModel: TAppViewModel { get }
    @ViewBuilder var bottom: TBottom? { get }
    
    var showToolbar: State<Bool> { get }
}

extension TnCameraAppViewProtocol {
    public var cameraModel: TnCameraViewModel {
        appModel.cameraModel
    }
    public var cameraManager: TAppViewModel.TCameraManager {
        appModel.cameraManager
    }
    public var cameraStatus: TnCameraStatus {
        cameraModel.status
    }
    public var cameraSettings: TnCameraSettings {
        cameraModel.settings
    }
}

extension TnCameraAppViewProtocol {
    public var body: some View {
        ZStack {
            if cameraStatus == .started {
                // preview
                TnCameraPreviewViewMetal(imagePublisher: cameraManager.currentCiImagePublisher)
                    .onTapGesture {
                        withAnimation {
                            showToolbar.wrappedValue.toggle()
                        }
                    }

                // bottom toolbar
                if showToolbar.wrappedValue {
                    VStack(alignment: .leading) {
                        Spacer()
                        if cameraModel.status == .started {
                            TnCameraToolbarMiscView(cameraManager: cameraManager)
                        }
                        TnCameraToolbarMainView(cameraManager: cameraManager, bottom: bottom)
                    }
                }
            }
        }
        .onAppear {
            appModel.setup()
        }
    }
}