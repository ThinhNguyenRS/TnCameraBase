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

    public init(config: TnTranscodingEncoderConfig) {
        self.encoder = TnTranscodingEncoder(config: config)
        self.adaptor = TnTranscodingEncoderAdaptor(encoder: encoder)
    }
    
    @discardableResult
    public func listen(packetHandler: @escaping TnTranscodingPacketHandler) -> Task<Void, Error> {
        Task { [self] in
            logDebug("listen packet ...")
            for await packet in adaptor.packetStream {
                logDebug("process packet ...")
                try await packetHandler(packet)
            }
        }
    }

    public func encode(_ pixelBuffer: CVPixelBuffer) async throws {
        try await encoder.encode(pixelBuffer)
    }
    
    public func invalidate() {
        encoder.invalidate()
    }
}

public typealias TnTranscodingPacketHandler = (Data) async throws -> Void

