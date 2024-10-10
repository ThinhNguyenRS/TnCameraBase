////
////  TnCameraAppViewSlaver.swift
////  TnCameraBase
////
////  Created by Thinh Nguyen on 10/10/24.
////
//
//import Foundation
//import SwiftUI
//import TnIosBase
//
//// MARK: TnCameraAppViewSlaver
//public struct TnCameraAppViewSlaver: View, TnLoggable {
//    public init(EOM: String? = nil, MTU: Int? = nil, encoder: TnEncoder, decoder: TnDecoder) {
//        let cameraProxy = TnCameraProxyClient(
//            bleInfo: TnCameraProxyServiceInfo.getBle(),
//            transportingInfo: TnCameraProxyServiceInfo.getTransporting(EOM: EOM, MTU: MTU, encoder: encoder, decoder: decoder)
//        )
//        cameraProxy.bleDelegate = cameraProxy
//        globalCameraProxy = cameraProxy
//        globalCameraProxy.setup()
//    }
//    
//    public var body: some View {
//        TnCameraAppViewInternal(delegate: self)
//    }
//}
//
//extension TnCameraAppViewSlaver: TnCameraAppViewDelegate {
//    func onChanged(status: TnCameraStatus, settings: TnCameraSettings) {
//    }
//}
