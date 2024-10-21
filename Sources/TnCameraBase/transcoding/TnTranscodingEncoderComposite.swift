//
//  TnTranscodingEncoder.swift
//  TnCameraBase
//
//  Created by Thinh Nguyen on 10/16/24.
//

import Foundation
import CoreImage
import TnIosBase

class TnTranscodingEncoderComposite: TnLoggable {
    private let encoder: TnTranscodingEncoder
    private let adaptor: TnTranscodingEncoderAdaptor
    private var stream: AsyncStream<Data>.Iterator
    
    public init(sendingName: [String] = ["streaming"]) {
        var config = TnTranscodingEncoderConfig.ultraLowLatency
        config.enableHardware = true
        self.encoder = TnTranscodingEncoder(config: config)
        self.adaptor = TnTranscodingEncoderAdaptor(encoder: encoder)
        self.stream = adaptor.makeStreamIterator()
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
            try await encoder.encode(pixelBuffer)
        }
    }
    
    public func invalidate() {
        encoder.invalidate()
    }
}

typealias TnTranscodingPacketHandler = (Data) async throws -> Void

