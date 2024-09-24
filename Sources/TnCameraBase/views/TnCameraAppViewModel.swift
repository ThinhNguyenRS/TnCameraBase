//
//  File.swift
//  
//
//  Created by Thinh Nguyen on 9/13/24.
//

import Foundation
import SwiftUI
import TnIosBase

public class TnCameraAppViewModel<TCameraProxy: TnCameraProxyProtocol>: NSObject, ObservableObject, TnLoggable {    
    public let cameraProxy: TCameraProxy
    @Published public var cameraModel: TnCameraViewModel
    @Published public var showToolbar: Bool = true
    let listenOrientation: Bool
    
    public init(
        cameraProxy: TCameraProxy,
        cameraModel: TnCameraViewModel,
        listenOrientation: Bool = true
    ) {
        self.cameraProxy = cameraProxy
        self.cameraModel = cameraModel
        self.listenOrientation = listenOrientation
        super.init()
        
        logDebug("inited")
    }
    
    public func setup() {
        cameraModel.listen(manager: cameraProxy, withOrientation: listenOrientation)
        cameraProxy.setup()
    }
}
