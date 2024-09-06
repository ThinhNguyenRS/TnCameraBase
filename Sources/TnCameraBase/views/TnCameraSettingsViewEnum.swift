//
//  SettingsEnum.swift
//  tCamera
//
//  Created by Thinh Nguyen on 8/7/24.
//

import SwiftUI
import TnIosBase

public struct TnCameraSettingsViewEnum<TValue: TnEnum, TStyle: PickerStyle, TTopView: View, TBottomView: View>: View, TnCameraViewProtocol {
    @EnvironmentObject public var cameraModel: TnCameraViewModel

    @Binding var value: TValue
    let label: String
    let values: [TValue]?
    let labels: [String]?
    let onChanged: ((TValue) -> Void)?
    let style: () -> TStyle
    
    @ViewBuilder let topView: () -> TTopView
    @ViewBuilder let bottomView: () -> TBottomView
    
    var closeable = true

    public var body: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack {
                    tnText(label)
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
            TnLogger.debug("CameraSettingsEnumView", "init", cameraModel.toolbarType, value.description)
        }
        .onChange(of: value, perform: { v in
            self.onChanged?(value)
        })
    }
}
