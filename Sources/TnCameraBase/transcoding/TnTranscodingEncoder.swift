//
//  TnTranscodingEncoderInternal.swift
//  TnCameraBase
//
//  Created by Thinh Nguyen on 10/17/24.
//

import Foundation
import VideoToolbox
import TnIosBase

public class TnTranscodingEncoder: TnLoggable {
    private var compressionSession: VTCompressionSession? = nil
    private var outputSize: CGSize? = nil
    private let config: TnTranscodingEncoderConfig
    
    private let imageStreamer: TnAsyncStreamer<CMSampleBuffer>

    public init(config: TnTranscodingEncoderConfig) {
        self.config = config
        imageStreamer = .init()
    }

    public var imageStream: AsyncStream<CMSampleBuffer> {
        imageStreamer.stream
    }

    public func invalidate() {
        if let compressionSession {
            VTCompressionSessionInvalidate(compressionSession)
        }
        compressionSession = nil
        outputSize = nil
    }

    public func encode(_ sampleBuffer: CMSampleBuffer) async throws {
        guard let imageBuffer = sampleBuffer.imageBuffer else {
            throw TnTranscodingError.general(message: "Input sample buffer is invalid")
        }
        try await encode(
            imageBuffer,
            presentationTimeStamp: sampleBuffer.presentationTimeStamp,
            duration: sampleBuffer.duration
        )
    }

    public func encode(_ pixelBuffer: CVPixelBuffer, presentationTimeStamp: CMTime = CMClockGetTime(.hostTimeClock), duration: CMTime = .invalid) async throws {
        if outputSize == nil {
            let pixelBufferWidth = CGFloat(CVPixelBufferGetWidth(pixelBuffer))
            let pixelBufferHeight = CGFloat(CVPixelBufferGetHeight(pixelBuffer))
            outputSize = CGSize(width: pixelBufferWidth, height: pixelBufferHeight)
        }
        if compressionSession == nil {
            compressionSession = try createCompressionSession()
        }
        
        guard let compressionSession else {
            throw TnAppError.general(message: "No compress session")
        }

        guard CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0)) == kCVReturnSuccess else {
            return
        }

        defer {
            CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        }
        
        if let sampleBuffer = try await compressionSession.encodeFrame(pixelBuffer, presentationTimeStamp: presentationTimeStamp, duration: duration) {
            imageStreamer.yield(sampleBuffer)
        }
    }
    
    private func createCompressionSession() throws -> VTCompressionSession {
        let session = try VTCompressionSession.create(
            size: outputSize!,
            codecType: config.codecType,
            encoderSpecification: config.encoderSpecification
        )
        config.apply(to: session)
        VTCompressionSessionPrepareToEncodeFrames(session)
        return session
    }
}

extension VTCompressionSession {
    static func create(
        size: CGSize,
        codecType: CMVideoCodecType,
        encoderSpecification: CFDictionary
    ) throws -> VTCompressionSession {
        var session: VTCompressionSession?
        try tnOsExecThrow("VTCompressionSessionCreate") {
            VTCompressionSessionCreate(
                allocator: nil,
                width: Int32(size.width),
                height: Int32(size.height),
                codecType: codecType,
                encoderSpecification: encoderSpecification,
                imageBufferAttributes: nil,
                compressedDataAllocator: nil,
                outputCallback: nil,
                refcon: nil,
                compressionSessionOut: &session
            )
        }
        guard let session else {
            throw TnAppError.general(message: "Cannot create compression session")
        }
        return session
    }

    func encodeFrame(
        _ pixelBuffer: CVPixelBuffer,
        presentationTimeStamp: CMTime,
        duration: CMTime
    ) async throws -> CMSampleBuffer? {
        var infoFlagsOut = VTEncodeInfoFlags()
        return try await withCheckedThrowingContinuation { continuation in
            let status = VTCompressionSessionEncodeFrame(
                self,
                imageBuffer: pixelBuffer,
                presentationTimeStamp: presentationTimeStamp,
                duration: duration,
                frameProperties: nil,
                infoFlagsOut: &infoFlagsOut,
                outputHandler: { status, _, sampleBuffer in
                    if let error = TnTranscodingError(status: status) {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: sampleBuffer)
                    }
                }
            )
            
            if let error = TnTranscodingError(status: status) {
                continuation.resume(throwing: error)
            }
        }
    }
}
