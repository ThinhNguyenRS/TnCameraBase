//
//  AppViewModelDefault.swift
//  TnCameraMaster
//
//  Created by Thinh Nguyen on 9/6/24.
//

import Foundation
import TnIosBase

open class TnCameraAppViewModelDefault<TCameraManager: TnCameraProxyProtocol>: NSObject, ObservableObject, TnCameraAppViewModelProtocol, TnLoggable {
    public var LOG_NAME = "AppViewModelDefault"
    
    public var cameraManager: TCameraManager
    public var cameraModel: TnCameraViewModel
    
    public init(cameraManager: TCameraManager, cameraModel: TnCameraViewModel) {
        self.cameraManager = cameraManager
        self.cameraModel = cameraModel
        super.init()
        
        logDebug("inited")
    }
    
    open func setup() {
        self.setup(withOrientation: true)
    }
    
    public func setup(withOrientation: Bool) {
        cameraModel.listen(manager: cameraManager, withOrientation: withOrientation)
        cameraManager.setup()
    }
}
