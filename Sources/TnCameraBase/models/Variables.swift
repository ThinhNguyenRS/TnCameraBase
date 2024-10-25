//
//  Variables.swift
//  TnCameraBase
//
//  Created by Thinh Nguyen on 9/24/24.
//

import Foundation
import Combine
import SwiftUI
import CoreData

var globalCamera: TnCameraProxyParams!

extension View {
    var cameraProxy: TnCameraProtocol {
        get {
            globalCamera.cameraProxy
        }
//        set {
//            globalCameraProxy = newValue
//        }
    }
}
