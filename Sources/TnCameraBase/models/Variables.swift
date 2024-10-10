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

var globalCameraProxy: TnCameraProxyProtocol!
var globalCameraSettingsID: NSManagedObjectID!

extension View {
    var cameraProxy: TnCameraProxyProtocol {
        get {
            globalCameraProxy
        }
        set {
            globalCameraProxy = newValue
        }
    }
}
