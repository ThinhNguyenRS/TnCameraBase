//
//  AppViewModelProtocol.swift
//  TnCameraMaster
//
//  Created by Thinh Nguyen on 9/6/24.
//

import Foundation

public protocol TnCameraAppViewModelProtocol: ObservableObject {
    associatedtype TCameraManager: TnCameraProxyProtocol
    var cameraManager: TCameraManager { get }
    var cameraModel: TnCameraViewModel { get }
    var showToolbar: Bool { get set }
    
    func setup()
}
