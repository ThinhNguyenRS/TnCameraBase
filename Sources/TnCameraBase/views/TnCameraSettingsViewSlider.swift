//
//  SettingsSlider.swift
//  tCamera
//
//  Created by Thinh Nguyen on 8/7/24.
//

import SwiftUI
import TnIosBase

public struct TnCameraSettingsViewSlider<TValue, TTopView: View, TBottomView: View>: View, TnCameraViewProtocol where TValue : BinaryFloatingPoint & CVarArg, TValue.Stride: BinaryFloatingPoint {
    @EnvironmentObject public var cameraModel: TnCameraViewModel

    @Binding var value: TValue
    let label: String

    let bounds: ClosedRange<TValue>
    let step: TValue.Stride

    let formatter: (TValue) -> String

    let onChanged: ((TValue) -> Void)?
    let onChanging: ((TValue) -> Void)?
    
    @ViewBuilder let topView: () -> TTopView
    @ViewBuilder let bottomView: () -> TBottomView

    var closeable = true
    
    var adjustBounds: Bool = false

    public var body: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack {
                    tnText("\(label) \(formatter(value))")
                    Spacer()
                    if closeable {
                        circleButton(imageName: "xmark", radius: 40) {
                            withAnimation {
                                cameraModel.toolbarType = .main
                            }
                        }
                    }
                }

                topView()

                TnSliderField(value: $value, bounds: bounds, step: step, formatter: formatter, onEdited:  { v in
                    onChanging?(v)
                }, adjustBounds: adjustBounds)

                bottomView()
            }
        }
        .onAppear {
            TnLogger.debug("CameraSettingsSliderView", "init", label, value)
        }
    }
}
