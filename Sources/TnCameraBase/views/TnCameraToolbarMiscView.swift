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
    @EnvironmentObject var cameraModel: TnCameraViewModel
    let cameraProxy: TnCameraProxyProtocol
    
    init(cameraProxy: TnCameraProxyProtocol) {
        self.cameraProxy = cameraProxy
        logDebug("inited")
    }
    
    public var body: some View {
        Group {
            switch cameraModel.toolbarType {
            case .zoom:
//                zoomView
                ZoomView(cameraProxy: cameraProxy)
            case .misc:
//                miscView
                MiscView(cameraProxy: cameraProxy)
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
    @EnvironmentObject var cameraModel: TnCameraViewModel
    let cameraProxy: TnCameraProxyProtocol

    init(cameraProxy: TnCameraProxyProtocol) {
        self.cameraProxy = cameraProxy
        logDebug("inited")
    }
    
    var body: some View {
        List {
            Section("Camera Type") {
                tnPickerViewVert(
                    label: "Preset",
                    value: $cameraModel.settings.preset,
                    values: cameraModel.settings.presets,
                    onChanged: { v in
                        cameraProxy.setPreset(v)
                    }
                )
                
                tnPickerViewVert(
                    label: "Type",
                    value: $cameraModel.settings.cameraType,
                    values: cameraModel.settings.cameraTypes,
                    onChanged: { v in
                        cameraProxy.setCameraType(v)
                    }
                )
                
                tnPickerViewVert(
                    label: "Priority",
                    value: $cameraModel.settings.priority,
                    onChanged: { v in
                        cameraProxy.setPriority(v)
                    }
                )
                
                TnToggleField(label: "Wide color", value: $cameraModel.settings.wideColor) { v in
                    cameraProxy.setWideColor(v)
                }
                .toggleStyle(.switch)

                if cameraModel.settings.livephotoSupported {
                    TnToggleField(label: "Live photo", value: $cameraModel.settings.livephoto) { v in
                        cameraProxy.setLivephoto(v)
                    }
                    .toggleStyle(.switch)
                }
            }
            
            Section("Capturing") {
                Stepper("Count: \(cameraModel.settings.capturing.count)", value: $cameraModel.settings.capturing.count, onEditingChanged: { _ in
                    cameraProxy.setCapturing(cameraModel.settings.capturing)
                })
                Stepper("Delay: \(cameraModel.settings.capturing.delay)s", value: $cameraModel.settings.capturing.delay, in: 0...10, onEditingChanged: { _ in
                    cameraProxy.setCapturing(cameraModel.settings.capturing)
                })
                
                SelectAlbumView(
                    album: $cameraModel.settings.capturing.album,
                    albumNames: cameraProxy.albums,
                    cameraProxy: cameraProxy
                )
            }
            
            Section("Light") {
                if cameraModel.settings.flashSupported {
                    tnPickerViewVert(
                        label: "Flash",
                        value: $cameraModel.settings.flashMode,
                        values: cameraModel.settings.flashModes,
                        onChanged: { v in
                            cameraProxy.setFlash(v)
                        }
                    )
                }
                
                if cameraModel.settings.hdrSupported {
                    tnPickerViewVert(
                        label: "HDR",
                        value: $cameraModel.settings.hdr,
                        onChanged: { v in
                            cameraProxy.setHDR(v)
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
                            cameraProxy.setFocusMode(v)
                        }
                    )
                }

                tnPickerViewVert(
                    label: "Exposure mode",
                    value: $cameraModel.settings.exposureMode,
                    values: cameraModel.settings.exposureModes,
                    onChanged: { v in
                        cameraProxy.setExposureMode(v)
                    }
                )
                
                if cameraModel.settings.exposureMode == .custom {
                    VStack {
                        tnSliderViewVert(
                            value: $cameraModel.settings.iso,
                            label: "ISO",
                            bounds: cameraModel.settings.isoRange,
                            step: 50,
                            onChanged: { [self] v in
                                cameraProxy.setExposure(.init(iso: v))
                            },
                            formatter: getNumberFormatter("%.0f")
                        )
                        
                        tnSliderViewVert(
                            value: $cameraModel.settings.exposureDuration,
                            label: "Shutter speed",
                            bounds: cameraModel.settings.exposureDurationRange,
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
            
            if cameraModel.settings.depthSupported {
                Section("Virtual apecture") {
                    TnToggleField(label: "Embed depth data", value: $cameraModel.settings.depth) { v in
                        cameraProxy.setDepth(v)
                    }
                    .toggleStyle(.switch)
                    
                    if cameraModel.settings.portraitSupported {
                        TnToggleField(label: "Embed portrait data", value: $cameraModel.settings.portrait) { v in
                            cameraProxy.setPortrait(v)
                        }
                        .toggleStyle(.switch)
                    }
                }
            }

            Section("Image Mirroring") {
                tnSliderViewVert(
                    value: $cameraModel.settings.transporting.scale,
                    label: "Scale",
                    bounds: 0.02...0.40,
                    step: 0.01,
                    onChanged: { [self] v in
                        cameraProxy.setTransporting(cameraModel.settings.transporting)
                    },
                    formatter: getNumberPercentFormatter(),
                    adjustBounds: false
                )

                tnSliderViewVert(
                    value: $cameraModel.settings.transporting.compressQuality,
                    label: "Compress quality",
                    bounds: 0.25...1,
                    step: 0.05,
                    onChanged: { [self] v in
                        cameraProxy.setTransporting(cameraModel.settings.transporting)
                    },
                    formatter: getNumberPercentFormatter(),
                    adjustBounds: false
                )

                TnToggleField(label: "Continuous", value: $cameraModel.settings.transporting.continuous) { v in
                    cameraProxy.setTransporting(cameraModel.settings.transporting)
                }
                .toggleStyle(.switch)
            }
        }
    }
}

struct ZoomView: View {
    @EnvironmentObject var cameraModel: TnCameraViewModel
    let cameraProxy: TnCameraProxyProtocol

    init(cameraProxy: TnCameraProxyProtocol) {
        self.cameraProxy = cameraProxy
    }
    
    var body: some View {
        let step = 0.1/2
        return tnSliderViewVert(
            value: $cameraModel.settings.zoomFactor,
            label: "Zoom",
            bounds: cameraModel.settings.zoomRange,
            step: step,
            onChanged: { v in
                cameraProxy.setZoomFactor(.init(value: v))
            },
            formatter: getNumberFormatter("%.2f"),
            bottomView: {
                HStack {
                    tnCircleButton(imageName: "chevron.backward", radius: 40) {
                        cameraProxy.setZoomFactor(.init(value: cameraModel.settings.zoomFactor - step))
                    }
                    
                    Spacer()
                    tnForEach(cameraModel.settings.zoomRelativeFactors) { idx, v in
                        Group {
                            tnCircleButton(text: v.toString("%0.1f"), radius: 36, backColor: cameraModel.settings.zoomFactor == v ? .orange : .gray) {
                                cameraProxy.setZoomFactor(.init(value: v))
                            }
                            Spacer()
                        }
                    }

                    tnCircleButton(imageName: "chevron.forward", radius: 40) {
                        cameraProxy.setZoomFactor(.init(value: cameraModel.settings.zoomFactor + step))
                    }
                }
            }
        )
    }
}

struct SelectAlbumView: View, TnLoggable {
    let cameraProxy: TnCameraProxyProtocol
    @Binding var album: String
    let albumNames: [String]
    let albumLabels: [String]

    @State private var showSheet = false
    @State private var newAlbum = ""

    init(album: Binding<String>, albumNames: [String], cameraProxy: TnCameraProxyProtocol) {
        _album = album
        self.albumNames = [""] + albumNames
        self.albumLabels = ["Default album"] + albumNames
        self.cameraProxy = cameraProxy
        
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
