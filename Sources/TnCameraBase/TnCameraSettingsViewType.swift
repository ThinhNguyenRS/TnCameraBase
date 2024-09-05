//
//  SettingsViewType.swift
//  tCamera
//
//  Created by Thinh Nguyen on 8/7/24.
//

import Foundation

public enum TnCameraSettingsViewType: Int {
    case none
    case main
    case flash
    case livephoto
    case ev
    case brightness
    case zoom
    case exposure
    case position
    case preset
    case cameraType
    case timer
    case hdr
    case filter
    
    case misc
}

extension TnCameraSettingsViewType: Comparable {
    public static func < (lhs: TnCameraSettingsViewType, rhs: TnCameraSettingsViewType) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
