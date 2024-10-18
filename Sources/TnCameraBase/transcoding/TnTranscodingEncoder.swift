//
//  TnTranscodingEncoder.swift
//  TnCameraBase
//
//  Created by Thinh Nguyen on 10/16/24.
//

import Foundation
import CoreImage
import TnIosBase

import Transcoding
class TnTranscodingEncoderWrapper: TnLoggable {
    private let encoder: VideoEncoder
    private let adaptor: VideoEncoderAnnexBAdaptor
    private var stream: AsyncStream<Data>.Iterator
    
    private let encodingQueue = DispatchQueue(label: "TnTranscodingEncoder.encoding", qos: .background)

    public init(sendingName: [String] = ["streaming"]) {
        self.encoder = VideoEncoder(config: .ultraLowLatency)
        self.adaptor = VideoEncoderAnnexBAdaptor(videoEncoder: encoder)
        self.stream = adaptor.annexBData.makeAsyncIterator()

    }
    
//    public func listen(packetHandler: @escaping (Data) async throws -> Void) throws {
//        Task { [self] in
//            while true {
//                guard let packet = await stream.next() else {
//                    try? await Task.sleep(nanoseconds: 1_000_000)
//                    continue
//                }
//                try await packetHandler(packet)
//            }
//        }
//    }
    
    public func encode(_ ciImage: CIImage?, packetHandler: @escaping TnTranscodingPacketHandler) async throws {
//        if let pixelBuffer = ciImage?.pixelBuffer {
//            logDebug("encode")
//            try await encoder.encode(pixelBuffer)
//            
//            // solve packets too
//            while let packet = await stream.next() {
//                logDebug("deliver packet")
//                try await packetHandler(packet)
//            }
//        }
        encodingQueue.async { [self] in
            if let pixelBuffer = ciImage?.pixelBuffer {
                encoder.encode(pixelBuffer)
            }
        }
    }
    
    public func invalidate() {
        encodingQueue.async { [self] in
            encoder.invalidate()
        }
    }
}

class TnTranscodingEncoderImpl: TnLoggable {
    private let encoder: TnTranscodingEncoderInternal
    private let adaptor: TnTranscodingEncoderAdaptor
    private var stream: AsyncStream<Data>.Iterator
    
    private let mainQueue: DispatchQueue
    private let outputQueue: DispatchQueue

    public init(sendingName: [String] = ["streaming"]) {
        self.encoder = TnTranscodingEncoderInternal(config: .ultraLowLatency)
        self.adaptor = TnTranscodingEncoderAdaptor(encoder: encoder)
        self.stream = adaptor.makeStreamIterator()
        self.mainQueue = DispatchQueue(label: "\(Self.self).main", qos: .background)
        self.outputQueue = DispatchQueue(label: "\(Self.self).output", qos: .background)
    }
    
    public func listen(packetHandler: @escaping TnTranscodingPacketHandler) throws {
        Task { [self] in
            while let packet = await stream.next() {
                try await packetHandler(packet)
            }
        }
    }
    
    public func encode(_ ciImage: CIImage?) async throws {
        if let pixelBuffer = ciImage?.pixelBuffer {
            logDebug("encode")
            try await encoder.encode(pixelBuffer)
        }
    }
    
    public func invalidate() {
        encoder.invalidate()
    }
}

typealias TnTranscodingPacketHandler = (Data) async throws -> Void

