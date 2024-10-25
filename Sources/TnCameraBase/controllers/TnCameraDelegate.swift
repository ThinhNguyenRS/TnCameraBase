//
//  TnCameraDelegate.swift
//  TnCameraBase
//
//  Created by Thinh Nguyen on 10/16/24.
//

import Foundation
import CoreImage

// MARK: TnCameraDelegate
public protocol TnCameraDelegate {
    func tnCamera(_ cameraProxy: TnCameraProtocol, captured: TnCameraPhotoOutput)
    func tnCamera(_ cameraProxy: TnCameraProtocol, status: TnCameraStatus)
    func tnCamera(_ cameraProxy: TnCameraProtocol, settings: TnCameraSettings)
    func tnCamera(_ cameraProxy: TnCameraProtocol, output: CIImage?)
}
