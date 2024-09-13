////
////  AppViewProtocol.swift
////  TnCameraMaster
////
////  Created by Thinh Nguyen on 9/6/24.
////
//
//import Foundation
//import SwiftUI
//
//public protocol TnCameraAppViewProtocol: View {
//    associatedtype TAppViewModel: TnCameraAppViewModelProtocol
//    associatedtype TBottom: View
//    
//    @ViewBuilder var bottom: TBottom? { get }
//
//    var appModelState: StateObject<TAppViewModel> { get }
//}
//
//extension TnCameraAppViewProtocol {
//    public var appModel: TAppViewModel {
//        appModelState.wrappedValue
//    }
//    
//    public var cameraModel: TnCameraViewModel {
//        appModelState.wrappedValue.cameraModel
//    }
//    
//    public var cameraManager: TAppViewModel.TCameraManager {
//        appModelState.wrappedValue.cameraManager
//    }
//}
//
//extension TnCameraAppViewProtocol {
//    public var body: some View {
//        ZStack {
//            // preview
//            TnCameraPreviewViewMetal(imagePublisher: cameraManager.currentCiImagePublisher)
//                .onTapGesture {
//                    withAnimation {
//                        appModel.showToolbar.toggle()
//                    }
//                }
//
//            // bottom toolbar
//            if appModel.showToolbar {
//                VStack(alignment: .leading) {
//                    Spacer()
//                    TnCameraToolbarMiscView(cameraManager: cameraManager)
//                    TnCameraToolbarMainView(cameraManager: cameraManager, bottom: bottom)
//                }
//            }
//        }
//        .onAppear {
//            appModel.setup()
//        }
//    }
//}
