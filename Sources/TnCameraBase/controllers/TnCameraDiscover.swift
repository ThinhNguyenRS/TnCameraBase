//
//  TnCameraDiscover.swift
//  tCamera
//
//  Created by Thinh Nguyen on 7/15/24.
//

import Foundation
import AVFoundation

public class TnCameraDiscover {
    public class CameraDevice {
        let position: AVCaptureDevice.Position
        let type: AVCaptureDevice.DeviceType
        
        var rawValue: String {
            type.rawValue
        }
        
        var description: String {
            type.description
        }
        
        init(position: AVCaptureDevice.Position, type: AVCaptureDevice.DeviceType) {
            self.position = position
            self.type = type
        }
    }
        
    static private var _availableDevices: [CameraDevice]?
    public static func getAvailableDevices(for position: AVCaptureDevice.Position) -> [CameraDevice] {
        if _availableDevices == nil {
            let discover = AVCaptureDevice.DiscoverySession(
                deviceTypes: AVCaptureDevice.DeviceType.allCases,
                mediaType: .video,
                position: .unspecified)

//            for device in discover.devices {
//                //device.high
//                for format in device.formats {
//                    let maxDimensions = format.supportedMaxPhotoDimensions.last!
//                    if /*(maxDimensions.width == format.formatDescription.dimensions.width) &&*/ (format.isHighPhotoQualitySupported || format.isHighestPhotoQualitySupported) {
//                        TnLogger.debug(
//                            "\(getDeviceTypeName(device.deviceType)!) \(device.position.rawValue)",
//                            maxDimensions.name,
//                            format.formatDescription.dimensions.name,
//                            format.formatDescription.mediaSubType.description,
//                            format.isHighPhotoQualitySupported ? "high" : "    ",
//                            format.isHighestPhotoQualitySupported ? "highest" : "       ",
//    //                        format.description,
//                            ""
//                        )
//                    }
//                }
//            }
            _availableDevices = discover.devices.map { d in
//                CameraDevice(position: d.position, type: d.deviceType, dimensions: d.activeFormat.supportedMaxPhotoDimensions)
                CameraDevice(position: d.position, type: d.deviceType)
//                if #available(iOS 16.0, *) {
//                    CameraDevice(position: d.position, type: d.deviceType, dimensions: d.formats.last { v in v.isHighestPhotoQualitySupported}!.supportedMaxPhotoDimensions)
//                } else {
//                    // Fallback on earlier versions
//                }
            }
        }
        return _availableDevices!.filter { d in
            d.position == position
        }
    }
    
    public static func getAvailableDeviceTpes(for position: AVCaptureDevice.Position) -> [AVCaptureDevice.DeviceType] {
        getAvailableDevices(for: position).map { d in
            d.type
        }
    }
    
    public static func getAvailableDeviceNames(for position: AVCaptureDevice.Position) -> [String] {
        getAvailableDevices(for: position).map { d in
            d.description
        }
    }
}

