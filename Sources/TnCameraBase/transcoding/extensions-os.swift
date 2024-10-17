//
//  extensions-os.swift
//  TnCameraBase
//
//  Created by Thinh Nguyen on 10/17/24.
//

import Foundation
import TnIosBase

public func tnOsExecThrow(_ name: String, _ action: @escaping () -> OSStatus) throws {
    let status = action()
    if status != noErr {
        throw TnAppError.general(message: "Execute [\(name)] error. Status: \(status)")
    }
}

@discardableResult
public func tnOsExecLog(_ name: String, _ action: @escaping () -> OSStatus) -> Bool {
    let status = action()
    if status != noErr {
        TnLogger.error(name, "Execute error, status: \(status)")
        return false
    }
    return true
}

public func tnOsStatusThrow(_ name: String, _ status: OSStatus) throws {
    if status != noErr {
        throw TnAppError.general(message: "Execute [\(name)] error. Status: \(status)")
    }
}
