//
//  SettingsSlider.swift
//  tCamera
//
//  Created by Thinh Nguyen on 8/7/24.
//

import SwiftUI
import TnIosPackage

public struct TnCameraSettingsViewSlider<TValue, TTopView: View, TBottomView: View>: View, TnCameraViewProtocol where TValue : BinaryFloatingPoint & CVarArg, TValue.Stride: BinaryFloatingPoint {
    @EnvironmentObject public var cameraModel: TnCameraViewModel

    @Binding var value: TValue
    let label: String

    let bounds: ClosedRange<TValue>
    let step: TValue.Stride

    let specifier: String

    let onChanged: ((TValue) -> Void)?
    let onChanging: ((TValue) -> Void)?
    
    @ViewBuilder let topView: () -> TTopView
    @ViewBuilder let bottomView: () -> TBottomView

    var closeable = true

    public var body: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack {
                    tnText("\(label) \(value.toString(specifier))")
                    Spacer()
                    if closeable {
                        circleButton(imageName: "xmark", radius: 40) {
                            withAnimation {
                                cameraModel.settingsType = .main
                            }
                        }
                    }
                }

                topView()

                TnSliderField(value: $value, bounds: bounds, step: step, specifier: specifier, onEdited:  { v in
                    onChanging?(v)
                })

                bottomView()
            }
        }
        .onAppear {
            TnLogger.debug("CameraSettingsSliderView", "init", label, value)
        }
    }
}
