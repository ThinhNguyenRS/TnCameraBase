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
    
    var appModel: StateObject<TAppViewModel> { get }
    @ViewBuilder var bottom: TBottom? { get }
    
    var showToolbar: State<Bool> { get }
}

extension TnCameraAppViewProtocol {
    public var cameraModel: TnCameraViewModel {
        appModel.wrappedValue.cameraModel
    }
    public var cameraManager: TAppViewModel.TCameraManager {
        appModel.wrappedValue.cameraManager
    }
}

extension TnCameraAppViewProtocol {
    public var body: some View {
        ZStack {
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
                    TnCameraToolbarMiscView(cameraManager: cameraManager)
                    TnCameraToolbarMainView(cameraManager: cameraManager, bottom: bottom)
                }
            }
//            if cameraModel.status == .started {
//                // preview
//                TnCameraPreviewViewMetal(imagePublisher: cameraManager.currentCiImagePublisher)
//                    .onTapGesture {
//                        withAnimation {
//                            showToolbar.wrappedValue.toggle()
//                        }
//                    }
//
//                // bottom toolbar
//                if showToolbar.wrappedValue {
//                    VStack(alignment: .leading) {
//                        Spacer()
//                        TnCameraToolbarMiscView(cameraManager: cameraManager)
//                        TnCameraToolbarMainView(cameraManager: cameraManager, bottom: bottom)
//                    }
//                }
//            }
        }
        .onAppear {
            appModel.wrappedValue.setup()
        }
    }
}
