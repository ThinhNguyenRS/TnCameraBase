//
//  SettingsViewType.swift
//  tCamera
//
//  Created by Thinh Nguyen on 8/7/24.
//

import Foundation

public enum TnCameraToolbarViewType: Int {
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

extension TnCameraToolbarViewType: Comparable {
    public static func < (lhs: TnCameraToolbarViewType, rhs: TnCameraToolbarViewType) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
