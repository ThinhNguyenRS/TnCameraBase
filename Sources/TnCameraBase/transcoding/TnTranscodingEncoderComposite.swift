//
//  TnTranscodingEncoder.swift
//  TnCameraBase
//
//  Created by Thinh Nguyen on 10/16/24.
//

import Foundation
import CoreImage
import TnIosBase

public class TnTranscodingEncoderComposite: TnLoggable {
    private let encoder: TnTranscodingEncoder
    private let adaptor: TnTranscodingEncoderAdaptor
    
    private let inputStreamer: TnAsyncStreamer<CVPixelBuffer>
    
    public init() {
        var config = TnTranscodingEncoderConfig.ultraLowLatency
        config.enableHardware = true
        self.encoder = TnTranscodingEncoder(config: config)
        self.adaptor = TnTranscodingEncoderAdaptor(encoder: encoder)
        self.inputStreamer = .init(newest: 5)
        
        // listen the input CVPixelBuffer and send to encoder
        Task {
            for await pixelBuffer in inputStreamer.stream {
                try await encoder.encode(pixelBuffer)
            }
        }
    }
    
    @discardableResult
    public func listen(packetHandler: @escaping TnTranscodingPacketHandler) -> Task<Void, Error> {
        Task { [self] in
            for await packet in adaptor.packetStream {
                try await packetHandler(packet)
            }
        }
    }

    public func encode(_ ciImage: CIImage?) {
        // just queue to the stream
        if let pixelBuffer = ciImage?.pixelBuffer {
            Task {
                inputStreamer.yield(pixelBuffer)
            }
        }
    }
    
    public func invalidate() {
        encoder.invalidate()
    }
}

public typealias TnTranscodingPacketHandler = (Data) async throws -> Void

