//
//  File.swift
//  
//
//  Created by Thinh Nguyen on 9/13/24.
//

import Foundation
import SwiftUI
import TnIosBase

public class TnCameraAppViewModel<TCameraManager: TnCameraProxyProtocol>: NSObject, ObservableObject, TnLoggable {
    public let LOG_NAME = "TnCameraAppViewModel.\(TCameraManager.Type.self)"
    
    public let cameraManager: TCameraManager
    public let cameraModel: TnCameraViewModel
    @Published public var showToolbar: Bool = true
    let listenOrientation: Bool
    
    public init(
        cameraManager: TCameraManager,
        cameraModel: TnCameraViewModel,
        listenOrientation: Bool = true
    ) {
        self.cameraManager = cameraManager
        self.cameraModel = cameraModel
        self.listenOrientation = listenOrientation
        super.init()
        
        logDebug("inited")
    }
    
    public func setup() {
        cameraModel.listen(manager: cameraManager, withOrientation: listenOrientation)
        cameraManager.setup()
    }
}
