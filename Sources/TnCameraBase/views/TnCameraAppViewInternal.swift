//
//  TnCameraAppViewInternal.swift
//  TnCameraBase
//
//  Created by Thinh Nguyen on 10/10/24.
//

import Foundation
import SwiftUI
import TnIosBase

// MARK: TnCameraAppViewDelegate
protocol TnCameraAppViewDelegate {
    func onChanged(status: TnCameraStatus, settings: TnCameraSettings)
}

// MARK: TnCameraAppViewInternal
struct TnCameraAppViewInternal: View, TnLoggable {
    @State private var showToolbar = false
    @State private var toolbarType: TnCameraToolbarViewType = .main
    @State private var settings: TnCameraSettings = .init()
    @State private var status: TnCameraStatus = .none
    @State private var capturedImage: UIImage? = nil
    
    private let delegate: TnCameraAppViewDelegate?
    
    init(delegate: TnCameraAppViewDelegate? = nil) {
        self.delegate = delegate
        globalCameraProxy.delegate = self
        logDebug("inited")
    }
    
    var body: some View {
        ZStack {
            // background
            Rectangle()
                .fill(.black)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            if status == .started {
                // preview
                TnCameraPreviewViewMetal(imagePublisher: { await cameraProxy.currentCiImagePublisher })
                    .onTapGesture {
                        withAnimation {
                            showToolbar.toggle()
                        }
                    }
                // toolbar
                TnCameraToolbarView(
                    showToolbar: $showToolbar,
                    toolbarType: $toolbarType,
                    settings: $settings,
                    capturedImage: $capturedImage
                )
            }
        }
        .overlay(alignment: .top) {
            TnCameraToolbarTopView()
        }
        .onAppear {
            logDebug("appear")
        }
    }
}

extension TnCameraAppViewInternal: TnCameraDelegate {
    public func tnCamera(captured: TnCameraPhotoOutput) {
        capturedImage = UIImage(data: captured.photoData)
    }
    
    public func tnCamera(status: TnCameraStatus) {
        guard self.status != status else { return }
        
        DispatchQueue.main.async {
            logDebug("status changed", status)
            self.status = status
        }
        delegate?.onChanged(status: status, settings: settings)
    }
    
    public func tnCamera(settings: TnCameraSettings) {
        DispatchQueue.main.async {
            logDebug("settings changed")
            self.settings = settings
        }
        delegate?.onChanged(status: status, settings: settings)
    }
}
