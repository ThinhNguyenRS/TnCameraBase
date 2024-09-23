//
//  SettingsEnum.swift
//  tCamera
//
//  Created by Thinh Nguyen on 8/7/24.
//

import SwiftUI
import TnIosBase

public struct TnCameraSettingsViewEnum<TValue: TnEnum, TStyle: PickerStyle, TTopView: View, TBottomView: View>: View {
    @Binding var value: TValue
    let label: String
    let values: [TValue]?
    let labels: [String]?
    let onChanged: ((TValue) -> Void)?
    let style: () -> TStyle
    
    @ViewBuilder let topView: () -> TTopView
    @ViewBuilder let bottomView: () -> TBottomView
    
    public var body: some View {
        HStack {
            VStack(alignment: .leading) {
                tnText(label)

                topView()

                TnPickerField(
                    label: "",
                    value: $value,
                    values: values ?? TValue.allCases,
                    labels: (values ?? TValue.allCases).map {v in v.description},
                    style: style                    
                )

                bottomView()
            }
            .padding(.all, 8)

        }
        .onAppear {
            TnLogger.debug("CameraSettingsEnumView", "appear", value.description)
        }
        .onChange(of: value, perform: { v in
            self.onChanged?(value)
        })
    }
}

extension View {
    public func getEnumView<TValue: TnEnum, TTopView: View, TBottomView: View>(
        value: Binding<TValue>,
        label: String, values: [TValue]? = nil,
        labels: [String]? = nil,
        style: @escaping () -> some PickerStyle,
        onChanged: @escaping (TValue) -> Void,
        @ViewBuilder topView: @escaping () -> TTopView,
        @ViewBuilder bottomView: @escaping () -> TBottomView
    ) -> some View {
        return TnCameraSettingsViewEnum(
            value: value,
            label: label,
            values: values,
            labels: labels,
            onChanged: onChanged,
            style: style,
            topView: topView,
            bottomView: bottomView
        )
        .transition(.moveAndFade)
    }
    
    public func getEnumView<TValue: TnEnum, TTopView: View, TBottomView: View>(
        value: Binding<TValue>,
        label: String,
        values: [TValue]? = nil,
        labels: [String]? = nil,
        onChanged: @escaping (TValue) -> Void,
        @ViewBuilder topView: @escaping () -> TTopView,
        @ViewBuilder bottomView: @escaping () -> TBottomView
    ) -> some View {
        getEnumView(
            value: value,
            label: label,
            values: values,
            labels: labels,
            style: {SegmentedPickerStyle()},
            onChanged: onChanged,
            topView: topView,
            bottomView: bottomView
        )
    }
    
    public func getEnumView<TValue: TnEnum, TBottomView: View>(
        value: Binding<TValue>,
        label: String,
        values: [TValue]? = nil,
        labels: [String]? = nil,
        onChanged: @escaping (TValue) -> Void,
        @ViewBuilder bottomView: @escaping () -> TBottomView
    ) -> some View {
        getEnumView(
            value: value,
            label: label,
            values: values,
            labels: labels,
            style: {SegmentedPickerStyle()},
            onChanged: onChanged,
            topView: { },
            bottomView: bottomView
        )
    }
    
    public func getEnumView<TValue: TnEnum>(
        value: Binding<TValue>,
        label: String,
        values: [TValue]? = nil,
        labels: [String]? = nil,
        onChanged: @escaping (TValue) -> Void
    ) -> some View {
        getEnumView(
            value: value,
            label: label,
            values: values,
            labels: labels,
            style: {SegmentedPickerStyle()},
            onChanged: onChanged,
            topView: { },
            bottomView: { }
        )
    }
}
