//
//  SettingsToolbar.swift
//  tCamera
//
//  Created by Thinh Nguyen on 7/30/24.
//

import Foundation
import SwiftUI
import TnIosBase

public struct TnCameraToolbarMiscView<TCameraProxy: TnCameraProxyProtocol>: View, TnCameraViewProtocol, TnLoggable {
//    @EnvironmentObject var appModel: TnCameraAppViewModel<TCameraProxy>
    
    @ObservedObject public var cameraModel: TnCameraViewModel
        
    let cameraProxy: TCameraProxy

    init(cameraModel: TnCameraViewModel, cameraProxy: TCameraProxy) {
        self.cameraModel = cameraModel
        self.cameraProxy = cameraProxy
        logDebug("inited")
    }
    
    public var body: some View {
        Group {
            switch cameraModel.toolbarType {
            case .zoom:
                ZoomView(cameraProxy: cameraProxy, settings: $cameraModel.settings)
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
                        getSliderView(
                            value: $cameraModel.settings.iso,
                            label: "ISO",
                            bounds: cameraModel.settings.isoRange,
                            step: 50,
                            onChanged: { [self] v in
                                cameraProxy.setExposure(.init(iso: v))
                            },
                            formatter: getNumberFormatter("%.0f")
                        )
                        
                        getSliderView(
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
                getSliderView(
                    value: $cameraModel.settings.transporting.scale,
                    label: "Scale",
                    bounds: 0.02...0.40,
                    step: 0.01,
                    onChanged: { [self] v in
                        cameraProxy.setTransport(cameraModel.settings.transporting)
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
                        cameraProxy.setTransport(cameraModel.settings.transporting)
                    },
                    formatter: getNumberPercentFormatter(),
                    adjustBounds: false
                )

                TnToggleField(label: "Continuous", value: $cameraModel.settings.transporting.continuous) { v in
                    cameraProxy.setTransport(cameraModel.settings.transporting)
                }
                .toggleStyle(.switch)
            }
        }
    }
}

struct ZoomView<TCameraProxy: TnCameraProxyProtocol>: View {
    let cameraProxy: TCameraProxy
    @Binding var settings: TnCameraSettings
    
    var body: some View {
        let step = 0.1/2
        return getSliderView(
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

struct SelectAlbumView<TCameraProxy: TnCameraProxyProtocol>: View, TnLoggable {
    let cameraProxy: TCameraProxy
    @Binding var album: String
    var albumNames: [String]
    
    @State private var showSheet = false
    @State private var newAlbum = ""

    init(album: Binding<String>, albumNames: [String], cameraProxy: TCameraProxy) {
        _album = album
        self.albumNames = [""] + albumNames
        self.cameraProxy = cameraProxy
        
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
