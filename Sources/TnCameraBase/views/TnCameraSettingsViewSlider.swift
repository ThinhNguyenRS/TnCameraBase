//
//  SettingsSlider.swift
//  tCamera
//
//  Created by Thinh Nguyen on 8/7/24.
//

import SwiftUI
import TnIosBase

public struct TnCameraSettingsViewSlider<TValue, TTopView: View, TBottomView: View>: View where TValue : BinaryFloatingPoint & CVarArg, TValue.Stride: BinaryFloatingPoint {
    @Binding var value: TValue
    let label: String

    let bounds: ClosedRange<TValue>
    let step: TValue.Stride

    let formatter: (TValue) -> String

    let onChanged: ((TValue) -> Void)?
    let onChanging: ((TValue) -> Void)?
    
    @ViewBuilder let topView: () -> TTopView
    @ViewBuilder let bottomView: () -> TBottomView

    var adjustBounds: Bool = false
    
    public var body: some View {
        HStack {
            VStack(alignment: .leading) {
                tnText("\(label) \(formatter(value))")

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

extension View {
    public func getSliderView<TValue, TTopView: View, TBottomView: View>(
        value: Binding<TValue>,
        label: String,
        bounds: ClosedRange<TValue>,
        step: TValue.Stride,
        onChanged: @escaping (TValue) -> Void,
        onChanging: @escaping (TValue) -> Void,
        formatter: @escaping (TValue) -> String = defaultNumberFormatter,
        @ViewBuilder topView: @escaping () -> TTopView,
        @ViewBuilder bottomView: @escaping () -> TBottomView,
        adjustBounds: Bool = false
    ) -> some View where TValue : BinaryFloatingPoint & CVarArg, TValue.Stride : BinaryFloatingPoint {
        TnCameraSettingsViewSlider(
            value: value,
            label: label,
            bounds: bounds,
            step: step,
            formatter: formatter,
            onChanged: onChanged,
            onChanging: onChanging,
            topView: topView,
            bottomView: bottomView,
            adjustBounds: adjustBounds
        )
    }
    
    public func getSliderView<TValue, TTopView: View>(
        value: Binding<TValue>,
        label: String,
        bounds: ClosedRange<TValue>,
        step: TValue.Stride,
        onChanged: @escaping (TValue) -> Void,
        onChanging: @escaping (TValue) -> Void,
        formatter: @escaping (TValue) -> String = defaultNumberFormatter,
        @ViewBuilder topView: @escaping () -> TTopView,
        adjustBounds: Bool = false
    ) -> some View where TValue : BinaryFloatingPoint & CVarArg, TValue.Stride : BinaryFloatingPoint {
        getSliderView(
            value: value,
            label: label,
            bounds: bounds,
            step: step,
            onChanged: onChanged,
            onChanging: onChanging,
            formatter: formatter,
            topView: topView,
            bottomView: { },
            adjustBounds: adjustBounds
        )
    }
    
    public func getSliderView<TValue, TBottomView: View>(
        value: Binding<TValue>,
        label: String, bounds: ClosedRange<TValue>,
        step: TValue.Stride,
        onChanged: @escaping (TValue) -> Void,
        onChanging: @escaping (TValue) -> Void,
        formatter: @escaping (TValue) -> String = defaultNumberFormatter,
        @ViewBuilder bottomView: @escaping () -> TBottomView,
        adjustBounds: Bool = false
    ) -> some View where TValue : BinaryFloatingPoint & CVarArg, TValue.Stride : BinaryFloatingPoint {
        getSliderView(
            value: value,
            label: label,
            bounds: bounds,
            step: step,
            onChanged: onChanged,
            onChanging: onChanging,
            formatter: formatter,
            topView: { },
            bottomView: bottomView,
            adjustBounds: adjustBounds
        )
    }
    
    public func getSliderView<TValue>(
        value: Binding<TValue>,
        label: String, bounds: ClosedRange<TValue>,
        step: TValue.Stride,
        onChanged: @escaping (TValue) -> Void,
        onChanging: @escaping (TValue) -> Void,
        formatter: @escaping (TValue) -> String = defaultNumberFormatter,
        adjustBounds: Bool = false
    ) -> some View where TValue : BinaryFloatingPoint & CVarArg, TValue.Stride : BinaryFloatingPoint {
        getSliderView(
            value: value,
            label: label,
            bounds: bounds,
            step: step,
            onChanged: onChanged,
            onChanging: onChanging,
            formatter: formatter,
            topView: { },
            bottomView: { },
            adjustBounds: adjustBounds
        )
    }
}
