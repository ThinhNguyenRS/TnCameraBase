//
//  SettingsToolbar.swift
//  tCamera
//
//  Created by Thinh Nguyen on 7/30/24.
//

import Foundation
import SwiftUI
import TnIosBase

public struct TnCameraToolbarMiscView: View, TnLoggable {
//    @EnvironmentObject var cameraModel: TnCameraViewModel
    
    @Binding var settings: TnCameraSettings
    @Binding var toolbarType: TnCameraToolbarViewType
    
    init(toolbarType: Binding<TnCameraToolbarViewType>, settings: Binding<TnCameraSettings>) {
        _toolbarType = toolbarType
        _settings = settings
        logDebug("inited")
    }
    
    public var body: some View {
        Group {
            switch toolbarType {
            case .zoom:
                ZoomView(settings: $settings)
            case .misc:
                MiscView(settings: $settings)
            default:
                EmptyView()
            }
        }
        .padding(.all, 12)
        .background(Color.appleAsparagus.opacity(0.75))
        .cornerRadius(8)
    }
}

struct MiscView: View, TnLoggable {
//    @EnvironmentObject var cameraModel: TnCameraViewModel
    @Binding var settings: TnCameraSettings

    init(settings: Binding<TnCameraSettings>) {
        _settings = settings
        logDebug("inited")
    }
    
    var body: some View {
        List {
            Section("Camera Type") {
                tnPickerViewVert(
                    label: "Preset",
                    value: $settings.preset,
                    values: settings.presets,
                    onChanged: { v in
                        cameraProxy.setPreset(v)
                    }
                )
                
                tnPickerViewVert(
                    label: "Type",
                    value: $settings.cameraType,
                    values: settings.cameraTypes,
                    onChanged: { v in
                        cameraProxy.setCameraType(v)
                    }
                )
                
                tnPickerViewVert(
                    label: "Priority",
                    value: $settings.priority,
                    onChanged: { v in
                        cameraProxy.setPriority(v)
                    }
                )
                
                TnToggleField(label: "Wide color", value: $settings.wideColor) { v in
                    cameraProxy.setWideColor(v)
                }
                .toggleStyle(.switch)

                if settings.livephotoSupported {
                    TnToggleField(label: "Live photo", value: $settings.livephoto) { v in
                        cameraProxy.setLivephoto(v)
                    }
                    .toggleStyle(.switch)
                }
            }
            
            Section("Capturing") {
                Stepper("Count: \(settings.capturing.count)", value: $settings.capturing.count, onEditingChanged: { _ in
                    cameraProxy.setCapturing(settings.capturing)
                })
                Stepper("Delay: \(settings.capturing.delay)s", value: $settings.capturing.delay, in: 0...10, onEditingChanged: { _ in
                    cameraProxy.setCapturing(settings.capturing)
                })
                
//                SelectAlbumView(
//                    album: $settings.capturing.album,
//                    albumNames: cameraProxy.albums
//                )
            }
            
            Section("Light") {
                if settings.flashSupported {
                    tnPickerViewVert(
                        label: "Flash",
                        value: $settings.flashMode,
                        values: settings.flashModes,
                        onChanged: { v in
                            cameraProxy.setFlash(v)
                        }
                    )
                }
                
                if settings.hdrSupported {
                    tnPickerViewVert(
                        label: "HDR",
                        value: $settings.hdr,
                        onChanged: { v in
                            cameraProxy.setHDR(v)
                        }
                    )

                }
            }
            
            Section("Exposure & Focus") {
                if !settings.focusModes.isEmpty {
                    tnPickerViewVert(
                        label: "Focus mode",
                        value: $settings.focusMode,
                        values: settings.focusModes,
                        onChanged: { v in
                            cameraProxy.setFocusMode(v)
                        }
                    )
                }

                tnPickerViewVert(
                    label: "Exposure mode",
                    value: $settings.exposureMode,
                    values: settings.exposureModes,
                    onChanged: { v in
                        cameraProxy.setExposureMode(v)
                    }
                )
                
                if settings.exposureMode == .custom {
                    VStack {
                        tnSliderViewVert(
                            value: $settings.iso,
                            label: "ISO",
                            bounds: settings.isoRange,
                            step: 50,
                            onChanged: { [self] v in
                                cameraProxy.setExposure(.init(iso: v))
                            },
                            formatter: getNumberFormatter("%.0f")
                        )
                        
                        tnSliderViewVert(
                            value: $settings.exposureDuration,
                            label: "Shutter speed",
                            bounds: settings.exposureDurationRange,
                            step: 0.001,
                            onChanged: { [self] v in
                                cameraProxy.setExposure(.init(duration: v))
                            },
                            formatter: getNumberFormatter("%.3f")
                        )
                    }
                    .padding(.horizontal, 16)
                }
            }
            
            if settings.depthSupported {
                Section("Virtual apecture") {
                    TnToggleField(label: "Embed depth data", value: $settings.depth) { v in
                        cameraProxy.setDepth(v)
                    }
                    .toggleStyle(.switch)
                    
                    if settings.portraitSupported {
                        TnToggleField(label: "Embed portrait data", value: $settings.portrait) { v in
                            cameraProxy.setPortrait(v)
                        }
                        .toggleStyle(.switch)
                    }
                }
            }

            Section("Image Mirroring") {
                tnSliderViewVert(
                    value: $settings.transporting.scale,
                    label: "Scale",
                    bounds: 0.02...0.40,
                    step: 0.01,
                    onChanged: { [self] v in
                        cameraProxy.setTransporting(settings.transporting)
                    },
                    formatter: getNumberPercentFormatter(),
                    adjustBounds: false
                )

                tnSliderViewVert(
                    value: $settings.transporting.compressQuality,
                    label: "Compress quality",
                    bounds: 0.25...1,
                    step: 0.05,
                    onChanged: { [self] v in
                        cameraProxy.setTransporting(settings.transporting)
                    },
                    formatter: getNumberPercentFormatter(),
                    adjustBounds: false
                )

                TnToggleField(label: "Continuous", value: $settings.transporting.continuous) { v in
                    cameraProxy.setTransporting(settings.transporting)
                }
                .toggleStyle(.switch)
            }
        }
    }
}

struct ZoomView: View, TnLoggable {
//    @EnvironmentObject var cameraModel: TnCameraViewModel
    @Binding var settings: TnCameraSettings

    init(settings: Binding<TnCameraSettings>) {
        _settings = settings
        logDebug("inited")
    }
    
    var body: some View {
        let step = 0.1/2
        return tnSliderViewVert(
            value: $settings.zoomFactor,
            label: "Zoom",
            bounds: settings.zoomRange,
            step: step,
            onChanged: { v in
                cameraProxy.setZoomFactor(.init(value: v))
            },
            formatter: getNumberFormatter("%.2f"),
            bottomView: {
                HStack {
                    tnCircleButton(imageName: "chevron.backward", radius: 40) {
                        cameraProxy.setZoomFactor(.init(value: settings.zoomFactor - step))
                    }
                    
                    Spacer()
                    tnForEach(settings.zoomRelativeFactors) { idx, v in
                        Group {
                            tnCircleButton(text: v.toString("%0.1f"), radius: 36, backColor: settings.zoomFactor == v ? .orange : .gray) {
                                cameraProxy.setZoomFactor(.init(value: v))
                            }
                            Spacer()
                        }
                    }

                    tnCircleButton(imageName: "chevron.forward", radius: 40) {
                        cameraProxy.setZoomFactor(.init(value: settings.zoomFactor + step))
                    }
                }
            }
        )
    }
}

struct SelectAlbumView: View, TnLoggable {
    @EnvironmentObject var cameraModel: TnCameraViewModel

    @Binding var album: String
    let albumNames: [String]
    let albumLabels: [String]

    @State private var showSheet = false
    @State private var newAlbum = ""

    init(album: Binding<String>, albumNames: [String]) {
        _album = album
        self.albumNames = [""] + albumNames
        self.albumLabels = ["Default album"] + albumNames
        
        logDebug("inited")
    }
    
    var body: some View {
        HStack() {
            tnPickerView(
                value: $album,
                values: albumNames,
                labels: albumLabels,
                onChanged: { _ in                
                },
                style: .menu
            )
            Spacer()
            tnCircleButton(imageName: "plus", radius: 32) {
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
                        cameraProxy.createAlbum(newAlbum)
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
