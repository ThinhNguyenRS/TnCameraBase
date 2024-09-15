//
//  SettingsView+base.swift
//  tCamera
//
//  Created by Thinh Nguyen on 7/30/24.
//

import SwiftUI
import TnIosBase

// MARK: camera views based
public protocol TnCameraViewProtocol {
    var cameraModel: TnCameraViewModel {get}
}

extension TnCameraViewProtocol {
    var orientation: UIDeviceOrientation {
        cameraModel.orientation
    }
    
    var orientationAngle: Angle {
        cameraModel.orientationAngle
    }
}

private let CIRCLE_RADIUS: CGFloat = 50.0
extension TnCameraViewProtocol {
    public func circleButtonRotation(imageName: String, radius: CGFloat? = nil,  backColor: Color = .background85Dark.opacity(0.8), imageColor: Color? = .white, animate: Bool = true, action: @escaping () -> Void) -> some View {
        tnCircleButton(imageName: imageName, radius: radius ?? CIRCLE_RADIUS, backColor: backColor, imageColor: imageColor, animate: animate) {
            action()
        }
        .rotationEffect(-orientationAngle)
    }
    
    public func circleButtonRotation(text: String, radius: CGFloat? = nil,  backColor: Color = .background85Dark.opacity(0.8), textColor: Color? = .white, animate: Bool = true, action: @escaping () -> Void) -> some View {
        tnCircleButton(text: text, radius: radius ?? CIRCLE_RADIUS, backColor: backColor, textColor: textColor, animate: animate) {
            action()
        }
        .rotationEffect(-orientationAngle)
    }
}

extension TnCameraViewProtocol {
    public func circleButton(
        imageName: String,
        radius: CGFloat? = nil,
        backColor: Color = .background85Dark.opacity(0.8),
        imageColor: Color? = .white,
        animate: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        tnCircleButton(imageName: imageName, radius: radius ?? CIRCLE_RADIUS, backColor: backColor, imageColor: imageColor, animate: animate) {
            action()
        }
    }
    
    public func circleButton(
        text: String,
        radius: CGFloat? = nil,
        backColor: Color = .background85Dark.opacity(0.8),
        textColor: Color? = .white,
        animate: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        tnCircleButton(text: text, radius: radius ?? CIRCLE_RADIUS, backColor: backColor, textColor: textColor, animate: animate) {
            action()
        }
    }
    
    public func getSettingsButton(type: TnCameraToolbarViewType, text: String) -> some View {
        circleButtonRotation(text: text) {
            withAnimation {
                if cameraModel.toolbarType != type {
                    cameraModel.toolbarType = type
                } else {
                    cameraModel.toolbarType = .none
                }
            }
        }
    }
    
    public func getSettingsButton(type: TnCameraToolbarViewType, imageName: String) -> some View {
        circleButtonRotation(imageName: imageName) {
            withAnimation {
                if cameraModel.toolbarType != type {
                    cameraModel.toolbarType = type
                } else {
                    cameraModel.toolbarType = .none
                }
            }
        }
    }
}

extension TnCameraViewProtocol {
    public func getEnumView<TValue: TnEnum, TTopView: View, TBottomView: View>(
        value: Binding<TValue>,
        label: String, values: [TValue]? = nil,
        labels: [String]? = nil,
        style: @escaping () -> some PickerStyle,
        onChanged: @escaping (TValue) -> Void,
        @ViewBuilder topView: @escaping () -> TTopView,
        @ViewBuilder bottomView: @escaping () -> TBottomView,
        closeable: Bool = true
    ) -> some View {
        return TnCameraSettingsViewEnum(
            value: value,
            label: label,
            values: values,
            labels: labels,
            onChanged: onChanged,
            style: style,
            topView: topView,
            bottomView: bottomView,
            closeable: closeable
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
        @ViewBuilder bottomView: @escaping () -> TBottomView,
        closeable: Bool = true
    ) -> some View {
        getEnumView(
            value: value,
            label: label,
            values: values,
            labels: labels,
            style: {SegmentedPickerStyle()},
            onChanged: onChanged,
            topView: topView,
            bottomView: bottomView,
            closeable: closeable
        )
    }
}

extension TnCameraViewProtocol {
    public func getSliderView<TValue, TTopView: View, TBottomView: View>(
        value: Binding<TValue>,
        label: String, 
        bounds: ClosedRange<TValue>,
        step: TValue.Stride,
        onChanged: @escaping (TValue) -> Void,
        onChanging: @escaping (TValue) -> Void,
        specifier: String = "%.0f",
        @ViewBuilder topView: @escaping () -> TTopView,
        @ViewBuilder bottomView: @escaping () -> TBottomView,
        closeable: Bool = true,
        adjustBounds: Bool = false
    ) -> some View where TValue : BinaryFloatingPoint & CVarArg, TValue.Stride : BinaryFloatingPoint {
        TnCameraSettingsViewSlider(
            value: value,
            label: label,
            bounds: bounds,
            step: step,
            specifier: specifier,
            onChanged: onChanged,
            onChanging: onChanging,
            topView: topView,
            bottomView: bottomView,
            closeable: closeable,
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
        specifier: String = "%.0f",
        @ViewBuilder topView: @escaping () -> TTopView,
        closeable: Bool = true,
        adjustBounds: Bool = false
    ) -> some View where TValue : BinaryFloatingPoint & CVarArg, TValue.Stride : BinaryFloatingPoint {
        getSliderView(
            value: value,
            label: label,
            bounds: bounds,
            step: step,
            onChanged: onChanged,
            onChanging: onChanging,
            specifier: specifier,
            topView: topView,
            bottomView: { },
            closeable: closeable,
            adjustBounds: adjustBounds
        )
    }

    public func getSliderView<TValue, TBottomView: View>(
        value: Binding<TValue>,
        label: String, bounds: ClosedRange<TValue>,
        step: TValue.Stride,
        onChanged: @escaping (TValue) -> Void,
        onChanging: @escaping (TValue) -> Void,
        specifier: String = "%.0f",
        @ViewBuilder bottomView: @escaping () -> TBottomView,
        closeable: Bool = true,
        adjustBounds: Bool = false
    ) -> some View where TValue : BinaryFloatingPoint & CVarArg, TValue.Stride : BinaryFloatingPoint {
        getSliderView(
            value: value,
            label: label,
            bounds: bounds,
            step: step,
            onChanged: onChanged,
            onChanging: onChanging,
            specifier: specifier,
            topView: { },
            bottomView: bottomView,
            closeable: closeable,
            adjustBounds: adjustBounds
        )
    }

    public func getSliderView<TValue>(
        value: Binding<TValue>,
        label: String, bounds: ClosedRange<TValue>,
        step: TValue.Stride,
        onChanged: @escaping (TValue) -> Void,
        onChanging: @escaping (TValue) -> Void,
        specifier: String = "%.0f",
        closeable: Bool = true,
        adjustBounds: Bool = false
    ) -> some View where TValue : BinaryFloatingPoint & CVarArg, TValue.Stride : BinaryFloatingPoint {
        getSliderView(
            value: value,
            label: label,
            bounds: bounds,
            step: step,
            onChanged: onChanged,
            onChanging: onChanging,
            specifier: specifier,
            topView: { },
            bottomView: { },
            closeable: closeable,
            adjustBounds: adjustBounds
        )
    }
}

