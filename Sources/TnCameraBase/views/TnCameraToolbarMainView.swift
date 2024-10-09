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

public struct TnCameraToolbarMainView: View, TnLoggable {
    @Binding private var capturedImage: UIImage?
    @Binding private var toolbarType: TnCameraToolbarViewType
    @Binding var settings: TnCameraSettings

    init(toolbarType: Binding<TnCameraToolbarViewType>, settings: Binding<TnCameraSettings>, capturedImage: Binding<UIImage?>) {
        self._toolbarType = toolbarType
        self._settings = settings
        self._capturedImage = capturedImage
        
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

struct TnCameraToolbarView: View, TnLoggable {
    @Binding private var showToolbar: Bool
    @Binding private var toolbarType: TnCameraToolbarViewType
    @Binding private var settings: TnCameraSettings
    @Binding private var capturedImage: UIImage?
    
    init(showToolbar: Binding<Bool>, toolbarType: Binding<TnCameraToolbarViewType>, settings: Binding<TnCameraSettings>, capturedImage: Binding<UIImage?>) {
        self._showToolbar = showToolbar
        self._toolbarType = toolbarType
        self._settings = settings
        self._capturedImage = capturedImage
        
        logDebug("inited")
    }
    
    var body: some View {
        // bottom toolbar
        if showToolbar {
            VStack(alignment: .leading) {
                Spacer()

                // variant toolbar
                if toolbarType == .zoom {
                    TnCameraToolbarZoomView(settings: $settings)
                        .padding(.all, 12)
                        .background(Color.appleAsparagus.opacity(0.75))
                        .cornerRadius(8)
                }
                else if toolbarType == .misc {
                    TnCameraToolbarMiscView(settings: $settings)
                }

                // main toolbar
                TnCameraToolbarMainView(toolbarType: $toolbarType, settings: $settings, capturedImage: $capturedImage)
            }
        }
    }
}

struct TnCameraToolbarTopView: View {
    var body: some View {
        HStack {
//            tnCircleButton(imageName: "photo.tv") {
//            }
            
            Spacer()
            tnCircleButton(imageName: "playpause") {
                cameraProxy.toggleCapturing()
            }
        }
        .padding(.all, 8)
    }
}
