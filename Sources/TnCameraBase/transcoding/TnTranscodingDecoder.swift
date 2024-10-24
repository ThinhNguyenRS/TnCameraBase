//
//  TnTranscodingDecoderInternal.swift
//  TnCameraBase
//
//  Created by Thinh Nguyen on 10/17/24.
//

import Foundation
import VideoToolbox
import TnIosBase


public class TnTranscodingDecoder: TnLoggable {
    private let config: TnTranscodingDecoderConfig
    private let streamer: TnAsyncStreamer<CMSampleBuffer>
    private var decompressionSession: VTDecompressionSession? = nil
    public private(set) var formatDescription: CMFormatDescription? = nil
    private lazy var outputQueue = DispatchQueue(
        label: "\(String(describing: Self.self)).output",
        qos: .userInitiated
    )

    public init(config: TnTranscodingDecoderConfig) {
        self.config = config
        streamer = .init()
    }

    public var stream: AsyncStream<CMSampleBuffer> {
        streamer.stream
    }

    public func invalidate() {
        if let decompressionSession {
            VTDecompressionSessionInvalidate(decompressionSession)
        }
        decompressionSession = nil
    }

    public func setFormatDescription(_ v: CMFormatDescription) throws {
        if let decompressionSession {
            if !VTDecompressionSessionCanAcceptFormatDescription(decompressionSession, formatDescription: v) {
                throw TnTranscodingError.general(message: "Invalid format description")
            }
        }
        self.formatDescription = v
    }

    public func decode(_ sampleBuffer: CMSampleBuffer) async throws {
        if decompressionSession == nil {
            decompressionSession = try createDecompressionSession()
        }        
        let sampleBufferOut = try await decompressionSession!.decodeFrame(sampleBuffer)
        outputQueue.sync {
            streamer.yield(sampleBufferOut)
        }
    }

    private func createDecompressionSession() throws -> VTDecompressionSession {
        guard let formatDescription else {
            throw TnTranscodingError.general(message: "Format description is nil")
        }
        let session = try VTDecompressionSession.create(
            formatDescription: formatDescription,
            decoderSpecification: config.decoderSpecification,
            imageBufferAttributes: nil
        )
        config.apply(to: session)
        return session
    }
}

extension VTDecompressionSession {
    static func create(formatDescription: CMVideoFormatDescription, decoderSpecification: CFDictionary, imageBufferAttributes: CFDictionary?) throws -> VTDecompressionSession {
        var session: VTDecompressionSession?
        try tnOsExecThrow("VTDecompressionSessionCreate") {
            VTDecompressionSessionCreate(
                allocator: nil,
                formatDescription: formatDescription,
                decoderSpecification: decoderSpecification,
                imageBufferAttributes: imageBufferAttributes,
                outputCallback: nil,
                decompressionSessionOut: &session
            )
        }
        guard let session else {
            throw TnTranscodingError.general(message: "Cannot create decompression session")
        }
        return session
    }
    
    func decodeFrame(_ sampleBuffer: CMSampleBuffer, flags decodeFlags: VTDecodeFrameFlags = [._1xRealTimePlayback]) async throws -> CMSampleBuffer {
        let decodeTimeStamp = sampleBuffer.decodeTimeStamp
        
        return try await withCheckedThrowingContinuation { continuation in
            var infoFlagsOut = VTDecodeInfoFlags()
            
            let status = VTDecompressionSessionDecodeFrame(
                self,
                sampleBuffer: sampleBuffer,
                flags: decodeFlags,
                infoFlagsOut: &infoFlagsOut,
                outputHandler: { status, _, imageBuffer, presentationTimeStamp, presentationDuration in
                    if let error = TnTranscodingError(status: status) {
                        continuation.resume(throwing: error)
                    } else {
                        if let imageBuffer {
                            do {
                                let formatDescription = try CMVideoFormatDescription(imageBuffer: imageBuffer)
                                let sampleTiming = CMSampleTimingInfo(
                                    duration: presentationDuration,
                                    presentationTimeStamp: presentationTimeStamp,
                                    decodeTimeStamp: decodeTimeStamp
                                )
                                let sampleBufferRet = try CMSampleBuffer(
                                    imageBuffer: imageBuffer,
                                    formatDescription: formatDescription,
                                    sampleTiming: sampleTiming
                                )
                                continuation.resume(returning: sampleBufferRet)
                            } catch {
                                continuation.resume(throwing: TnTranscodingError.general(message: "Cannot decode franme", error: error))
                            }
                        } else {
                            continuation.resume(throwing: TnTranscodingError.general(message: "Output image buffer is null"))
                        }
                    }
                }
            )
            
            if let error = TnTranscodingError(status: status) {
                continuation.resume(throwing: error)
            }
        }
    }
}
