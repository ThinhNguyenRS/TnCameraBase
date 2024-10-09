//
//  TnSwipe.swift
//  TnCameraBase
//
//  Created by Thinh Nguyen on 10/9/24.
//

import Foundation
import SwiftUI

enum TnSwipeSide {
    case left, right, up, down
}

extension View {
    func onSwipe(_ handler: @escaping (TnSwipeSide) -> Void) -> some View {
        self.gesture(DragGesture(minimumDistance: 3.0, coordinateSpace: .local)
            .onEnded { value in
                switch(value.translation.width, value.translation.height) {
                case (...0, -30...30): // left
                    handler(.left)
                    break
                case (0..., -30...30): // right
                    handler(.right)
                    break
                case (-100...100, ...0): // up
                    handler(.up)
                case (-100...100, 0...): // down
                    handler(.down)
                default:
                    break
                }
            }
        )
    }
}
