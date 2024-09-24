//
//  SettingsToolbar.swift
//  tCamera
//
//  Created by Thinh Nguyen on 7/30/24.
//

import Foundation
import SwiftUI
import TnIosBase

public struct TnCameraToolbarMiscView<TCameraManager: TnCameraProxyProtocol>: View, TnCameraViewProtocol, TnLoggable {
    @EnvironmentObject var appModel: TnCameraAppViewModel<TCameraManager>
//    @EnvironmentObject public var cameraModel: TnCameraViewModel
    
    @ObservedObject public var cameraModel: TnCameraViewModel
        
    let cameraManager: TCameraManager

    init(cameraModel: TnCameraViewModel, cameraManager: TCameraManager) {
        self.cameraModel = cameraModel
        self.cameraManager = cameraManager
        logDebug("inited")
    }
    
    public var body: some View {
        Group {
            switch cameraModel.toolbarType {
            case .zoom:
                ZoomView(cameraManager: cameraManager, settings: $cameraModel.settings)
            case .misc:
                miscView
            default:
                EmptyView()
            }
        }
        .padding(.all, 12)
        .background(Color.appleAsparagus.opacity(0.75))
        .cornerRadius(8)
    }
}

extension TnCameraToolbarMiscView {
    var miscView: some View {
        List {
            Section("Camera Type") {
                tnPickerViewVert(
                    label: "Preset",
                    value: $cameraModel.settings.preset,
                    values: cameraModel.settings.presets,
                    onChanged: { v in
                        cameraManager.setPreset(v)
                    }
                )
                
                tnPickerViewVert(
                    label: "Type",
                    value: $cameraModel.settings.cameraType,
                    values: cameraModel.settings.cameraTypes,
                    onChanged: { v in
                        cameraManager.setCameraType(v)
                    }
                )
                
                tnPickerViewVert(
                    label: "Priority",
                    value: $cameraModel.settings.priority,
                    onChanged: { v in
                        cameraManager.setPriority(v)
                    }
                )
                
                TnToggleField(label: "Wide color", value: $cameraModel.settings.wideColor) { v in
                    cameraManager.setWideColor(v)
                }
                .toggleStyle(.switch)

                if cameraModel.settings.livephotoSupported {
                    TnToggleField(label: "Live photo", value: $cameraModel.settings.livephoto) { v in
                        cameraManager.setLivephoto(v)
                    }
                    .toggleStyle(.switch)
                }
            }
            
            Section("Capturing") {
                Stepper("Count: \(cameraModel.settings.capturing.count)", value: $cameraModel.settings.capturing.count, onEditingChanged: { _ in
                    cameraManager.setCapturing(cameraModel.settings.capturing)
                })
                Stepper("Delay: \(cameraModel.settings.capturing.delay)s", value: $cameraModel.settings.capturing.delay, in: 0...10, onEditingChanged: { _ in
                    cameraManager.setCapturing(cameraModel.settings.capturing)
                })
                
                SelectAlbumView(
                    album: $cameraModel.settings.capturing.album,
                    albumNames: cameraManager.albums,
                    cameraManager: cameraManager
                )
            }
            
            Section("Light") {
                if cameraModel.settings.flashSupported {
                    tnPickerViewVert(
                        label: "Flash",
                        value: $cameraModel.settings.flashMode,
                        values: cameraModel.settings.flashModes,
                        onChanged: { v in
                            cameraManager.setFlash(v)
                        }
                    )
                }
                
                if cameraModel.settings.hdrSupported {
                    tnPickerViewVert(
                        label: "HDR",
                        value: $cameraModel.settings.hdr,
                        onChanged: { v in
                            cameraManager.setHDR(v)
                        }
                    )

                }
            }
            
            Section("Exposure & Focus") {
                if !cameraModel.settings.focusModes.isEmpty {
                    tnPickerViewVert(
                        label: "Focus mode",
                        value: $cameraModel.settings.focusMode,
                        values: cameraModel.settings.focusModes,
                        onChanged: { v in
                            cameraManager.setFocusMode(v)
                        }
                    )
                }

                tnPickerViewVert(
                    label: "Exposure mode",
                    value: $cameraModel.settings.exposureMode,
                    values: cameraModel.settings.exposureModes,
                    onChanged: { v in
                        cameraManager.setExposureMode(v)
                    }
                )
                
                if cameraModel.settings.exposureMode == .custom {
                    VStack {
                        getSliderView(
                            value: $cameraModel.settings.iso,
                            label: "ISO",
                            bounds: cameraModel.settings.isoRange,
                            step: 50,
                            onChanged: { [self] v in
                                cameraManager.setExposure(.init(iso: v))
                            },
                            formatter: getNumberFormatter("%.0f")
                        )
                        
                        getSliderView(
                            value: $cameraModel.settings.exposureDuration,
                            label: "Shutter speed",
                            bounds: cameraModel.settings.exposureDurationRange,
                            step: 0.001,
                            onChanged: { [self] v in
                                cameraManager.setExposure(.init(duration: v))
                            },
                            formatter: getNumberFormatter("%.3f")
                        )
                    }
                    .padding(.horizontal, 16)
                }
            }
            
            if cameraModel.settings.depthSupported {
                Section("Virtual apecture") {
                    TnToggleField(label: "Embed depth data", value: $cameraModel.settings.depth) { v in
                        cameraManager.setDepth(v)
                    }
                    .toggleStyle(.switch)
                    
                    if cameraModel.settings.portraitSupported {
                        TnToggleField(label: "Embed portrait data", value: $cameraModel.settings.portrait) { v in
                            cameraManager.setPortrait(v)
                        }
                        .toggleStyle(.switch)
                    }
                }
            }

            Section("Image Mirroring") {
                getSliderView(
                    value: $cameraModel.settings.transporting.scale,
                    label: "Scale",
                    bounds: 0.02...0.40,
                    step: 0.01,
                    onChanged: { [self] v in
                        cameraManager.setTransport(cameraModel.settings.transporting)
                    },
                    formatter: getNumberPercentFormatter(),
                    adjustBounds: false
                )

                getSliderView(
                    value: $cameraModel.settings.transporting.compressQuality,
                    label: "Compress quality",
                    bounds: 0.25...1,
                    step: 0.05,
                    onChanged: { [self] v in
                        cameraManager.setTransport(cameraModel.settings.transporting)
                    },
                    formatter: getNumberPercentFormatter(),
                    adjustBounds: false
                )

                TnToggleField(label: "Continuous", value: $cameraModel.settings.transporting.continuous) { v in
                    cameraManager.setTransport(cameraModel.settings.transporting)
                }
                .toggleStyle(.switch)
            }
        }
    }
}

struct ZoomView<TCameraManager: TnCameraProxyProtocol>: View {
    let cameraManager: TCameraManager
    @Binding var settings: TnCameraSettings
    
    var body: some View {
        let step = 0.1/2
        return getSliderView(
            value: $settings.zoomFactor,
            label: "Zoom",
            bounds: settings.zoomRange,
            step: step,
            onChanged: { v in
                cameraManager.setZoomFactor(.init(value: v))
            },
            formatter: getNumberFormatter("%.2f"),
            bottomView: {
                HStack {
                    tnCircleButton(imageName: "chevron.backward", radius: 40) {
                        cameraManager.setZoomFactor(.init(value: settings.zoomFactor - step))
                    }
                    
                    Spacer()
                    tnForEach(settings.zoomRelativeFactors) { idx, v in
                        Group {
                            tnCircleButton(text: v.toString("%0.1f"), radius: 36, backColor: settings.zoomFactor == v ? .orange : .gray) {
                                cameraManager.setZoomFactor(.init(value: v))
                            }
                            Spacer()
                        }
                    }

                    tnCircleButton(imageName: "chevron.forward", radius: 40) {
                        cameraManager.setZoomFactor(.init(value: settings.zoomFactor + step))
                    }
                }
            }
        )
    }
}

struct SelectAlbumView<TCameraManager: TnCameraProxyProtocol>: View, TnLoggable {
    let cameraManager: TCameraManager
    @Binding var album: String
    var albumNames: [String]
    
    @State private var showSheet = false
    @State private var newAlbum = ""

    init(album: Binding<String>, albumNames: [String], cameraManager: TCameraManager) {
        _album = album
        self.albumNames = [""] + albumNames
        self.cameraManager = cameraManager
        
        logDebug("inited")
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            tnPickerViewHorz(
                label: "Album",
                value: $album,
                values: albumNames,
                labels: albumNames,
                style: .menu
            )

            tnButton("New ...") {
                showSheet = true
            }
        }
        .sheet(isPresented: $showSheet) {
            VStack {
                Text("Create new album")
                TextField("New album name", text: $newAlbum)
                
                Spacer()
                HStack {
                    Spacer()
                    tnButton("Create") {
                        cameraManager.createAlbum(newAlbum)
                        album = newAlbum
                        showSheet = false
                    }
                    .disabled(newAlbum.isEmpty)

                    Spacer()
                    tnButton("Close") {
                        showSheet = false
                    }

                    Spacer()
                }
            }
            .padding(.all, 16)
        }
    }
}
