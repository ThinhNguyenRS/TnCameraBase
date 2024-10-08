//
//  SettingsView+base.swift
//  tCamera
//
//  Created by Thinh Nguyen on 7/30/24.
//

import SwiftUI
import TnIosBase

// MARK: View extensions
private let CIRCLE_RADIUS: CGFloat = 50.0

extension View {
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
    
    public func circleButtonRotation(imageName: String, radius: CGFloat? = nil,  backColor: Color = .background85Dark.opacity(0.8), imageColor: Color? = .white, animate: Bool = true, action: @escaping () -> Void) -> some View {
        tnCircleButton(imageName: imageName, radius: radius ?? CIRCLE_RADIUS, backColor: backColor, imageColor: imageColor, animate: animate) {
            action()
        }
    }
    
    public func circleButtonRotation(text: String, radius: CGFloat? = nil,  backColor: Color = .background85Dark.opacity(0.8), textColor: Color? = .white, animate: Bool = true, action: @escaping () -> Void) -> some View {
        tnCircleButton(text: text, radius: radius ?? CIRCLE_RADIUS, backColor: backColor, textColor: textColor, animate: animate) {
            action()
        }
    }
}
