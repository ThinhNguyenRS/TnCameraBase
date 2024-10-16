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
    func tnCamera(_ cameraProxy: TnCameraProxyProtocol, captured: TnCameraPhotoOutput)
    func tnCamera(_ cameraProxy: TnCameraProxyProtocol, status: TnCameraStatus)
    func tnCamera(_ cameraProxy: TnCameraProxyProtocol, settings: TnCameraSettings)
    func tnCamera(_ cameraProxy: TnCameraProxyProtocol, output: CIImage?)
}
