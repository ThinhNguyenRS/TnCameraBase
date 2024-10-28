//
//  TnTranscodingEncoderAdaptor.swift
//  TnCameraBase
//
//  Created by Thinh Nguyen on 10/17/24.
//

import Foundation
import VideoToolbox
import TnIosBase

public class TnTranscodingEncoderAdaptor: TnLoggable {
    private let encoder: TnTranscodingEncoder
    private let packetStreamer: TnAsyncStreamer<Data> = .init()
    
    public init(encoder: TnTranscodingEncoder) {
        self.encoder = encoder
        
        Task { [weak self] in
            for await sampleBuffer in encoder.imageStream {
                guard let self else { return }
                let sampleAttachments = CMSampleBufferGetSampleAttachmentsArray(
                    sampleBuffer,
                    createIfNecessary: false
                ) as? [[CFString: Any]]
                let notSync = sampleAttachments?.first?[kCMSampleAttachmentKey_NotSync] as? Bool ?? false
                
                var elementaryStream = Data()
                
                if !notSync {
                    guard let formatDesciption = sampleBuffer.formatDescription else {
                        logError("Encoded sample buffer missing format description")
                        continue
                    }
                    switch formatDesciption.mediaSubType {
                    case .h264:
                        guard formatDesciption.parameterSets.count > 1 else {
                            logError("Encoded sample buffer missing parameter set")
                            continue
                        }
                        elementaryStream += H264NALU(data: formatDesciption.parameterSets[0]).annexB
                        elementaryStream += H264NALU(data: formatDesciption.parameterSets[1]).annexB
                        
                    case .hevc:
                        guard formatDesciption.parameterSets.count > 2 else {
                            logError("Encoded sample buffer missing parameter set")
                            continue
                        }
                        elementaryStream += HEVCNALU(data: formatDesciption.parameterSets[0]).annexB
                        elementaryStream += HEVCNALU(data: formatDesciption.parameterSets[1]).annexB
                        elementaryStream += HEVCNALU(data: formatDesciption.parameterSets[2]).annexB
                    default:
                        logError("Encoded sample buffer has unsupported media sub type")
                        continue
                    }
                }
                guard let dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else {
                    logError("CMSampleBufferGetDataBuffer returned nil")
                    continue
                }
                var length: Int = 0
                var dataPointer: UnsafeMutablePointer<Int8>?
                let status = CMBlockBufferGetDataPointer(
                    dataBuffer,
                    atOffset: 0,
                    lengthAtOffsetOut: nil,
                    totalLengthOut: &length,
                    dataPointerOut: &dataPointer
                )
                guard status == noErr, let dataPointer else {
                    logError("CMBlockBufferGetDataPointer failed with status: \(status)")
                    continue
                }
                
                var offset = 0
                while offset < length {
                    var naluLength: UInt32 = 0
                    memcpy(&naluLength, dataPointer.advanced(by: offset), 4)
                    offset += 4
                    
                    switch sampleBuffer.formatDescription?.mediaSubType {
                    case .some(.h264):
                        elementaryStream += H264NALU(data: Data(
                            bytes: dataPointer.advanced(by: offset),
                            count: Int(naluLength.bigEndian)
                        )).annexB
                    case .some(.hevc):
                        elementaryStream += HEVCNALU(data: Data(
                            bytes: dataPointer.advanced(by: offset),
                            count: Int(naluLength.bigEndian)
                        )).annexB
                    default:
                        break
                    }
                    
                    offset += Int(naluLength.bigEndian)
                }
                
                packetStreamer.yield(elementaryStream)
                logDebug("yield packet")
            }
        }
    }
    
    public var packetStream: AsyncStream<Data> {
        packetStreamer.stream
    }
}
