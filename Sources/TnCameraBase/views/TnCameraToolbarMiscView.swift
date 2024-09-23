//
//  SettingsToolbar.swift
//  tCamera
//
//  Created by Thinh Nguyen on 7/30/24.
//

import Foundation
import SwiftUI
import TnIosBase

public struct TnCameraToolbarMiscView<TCameraManager: TnCameraProxyProtocol>: View, TnCameraViewProtocol {
    @EnvironmentObject public var cameraModel: TnCameraViewModel
    let cameraManager: TCameraManager

    public var body: some View {
        Group {
            switch cameraModel.toolbarType {
            case .zoom:
                zoomView                
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
    var zoomView: some View {
        let step = 0.1/2
        return getSliderView(
            value: $cameraModel.settings.zoomFactor,
            label: "Zoom",
            bounds: cameraModel.settings.zoomRange,
            step: step,
            onChanged: { _ in},
            onChanging: { [self] v in
                cameraManager.setZoomFactor(.init(value: v))
            },
            formatter: getNumberFormatter("%.2f"),
            bottomView: {
                HStack {
                    tnCircleButton(imageName: "chevron.backward", radius: 40) {
                        cameraManager.setZoomFactor(.init(value: cameraModel.settings.zoomFactor - step))
                    }
                    
                    Spacer()
                    tnForEach(cameraModel.settings.zoomRelativeFactors) { idx, v in
                        Group {
                            tnCircleButton(text: v.toString("%0.1f"), radius: 36, backColor: cameraModel.settings.zoomFactor == v ? .orange : .gray) {
                                cameraManager.setZoomFactor(.init(value: v))
                            }
                            Spacer()
                        }
                    }

                    tnCircleButton(imageName: "chevron.forward", radius: 40) {
                        cameraManager.setZoomFactor(.init(value: cameraModel.settings.zoomFactor + step))
                    }
                }
            },
            closeable: false
        )
    }
            
    var miscView: some View {
        List {
            Section("Camera Type") {
                TnPickerField.forEnum(
                    label: "Preset",
                    value: $cameraModel.settings.preset,
                    values: cameraModel.settings.presets,
                    onChanged: { v in
                        cameraManager.setPreset(v)
                    }
                )
                
                TnPickerField.forEnum(
                    label: "Type",
                    value: $cameraModel.settings.cameraType,
                    values: cameraModel.settings.cameraTypes,
                    onChanged: { v in
                        cameraManager.setCameraType(v)
                    }
                )
                
                TnPickerField.forEnum(label: "Priority", value: $cameraModel.settings.priority, onChanged: { v in
                    cameraManager.setPriority(v)
                })
                
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
                    albumNames: cameraManager.albums
                )
            }
            
            Section("Light") {
                if cameraModel.settings.flashSupported {
                    TnPickerField.forEnum(
                        label: "Flash",
                        value: $cameraModel.settings.flashMode,
                        values: cameraModel.settings.flashModes,
                        onChanged: { v in
                            cameraManager.setFlash(v)
                        }
                    )
                }
                
                if cameraModel.settings.hdrSupported {
                    TnPickerField.forEnum(
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
                    TnPickerField.forEnum(
                        label: "Focus mode",
                        value: $cameraModel.settings.focusMode,
                        values: cameraModel.settings.focusModes,
                        onChanged: { v in
                            cameraManager.setFocusMode(v)
                        }
                    )
                }

                TnPickerField.forEnum(
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
                            onChanged: { _ in},
                            onChanging: { [self] v in
                                cameraManager.setExposure(.init(iso: v))
                            },
                            formatter: getNumberFormatter("%.0f"),
                            closeable: false
                        )
                        
                        getSliderView(
                            value: $cameraModel.settings.exposureDuration,
                            label: "Shutter speed",
                            bounds: cameraModel.settings.exposureDurationRange,
                            step: 0.001,
                            onChanged: { _ in},
                            onChanging: { [self] v in
                                cameraManager.setExposure(.init(duration: v))
                            },
                            formatter: getNumberFormatter("%.3f"),
                            closeable: false
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
                    onChanged: { _ in},
                    onChanging: { [self] v in
                        cameraManager.setTransport(cameraModel.settings.transporting)
                    },
                    formatter: getNumberPercentFormatter(),
                    closeable: false,
                    adjustBounds: false
                )

                getSliderView(
                    value: $cameraModel.settings.transporting.compressQuality,
                    label: "Compress quality",
                    bounds: 0.25...1,
                    step: 0.05,
                    onChanged: { _ in},
                    onChanging: { [self] v in
                        cameraManager.setTransport(cameraModel.settings.transporting)
                    },
                    formatter: getNumberPercentFormatter(),
                    closeable: false,
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

struct SelectAlbumView: View {
    @Binding var album: String
    var albumNames: [String]
    
    var body: some View {
        Group {
            TextField("Album", text: $album, onEditingChanged: { _ in
    //            cameraManager.setCapturing(cameraModel.settings.capture)
            })

//            tnPickerFieldStringMenu(
//                label: "Select album",
//                value: $album,
//                labels: albumNames
//            )

            TnPickerFieldPopup(
                label: "Select album",
                value: $album,
                values: albumNames,
                labels: albumNames
            )
        }
    }
}
