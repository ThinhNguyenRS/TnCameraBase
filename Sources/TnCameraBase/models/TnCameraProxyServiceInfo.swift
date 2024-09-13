//
//  CameraBluetooth.swift
//  tCamera
//
//  Created by Thinh Nguyen on 8/17/24.
//

import Foundation
import CoreBluetooth
import TnIosBase

public struct TnCameraProxyServiceInfo {
    private init() {}
    
    public static func getInstance(EOM: String? = nil, MTU: Int? = nil) -> TnNetworkServiceInfo
    {
        TnNetworkServiceInfo(
            bleServiceUUID: CBUUID(string: "5C09399B-28D5-47EB-A9DF-DD994B9451A0"),
            bleCharacteristicUUID: CBUUID(string: "B20A40F8-6232-457C-8C8E-2A36F0C92945"),
            bleRssiMin: -100,
            EOM: (EOM ?? "$$$EOM$$$").data(using: .utf8)!,
            MTU: MTU ?? 1024*1024
        )
    }
}
