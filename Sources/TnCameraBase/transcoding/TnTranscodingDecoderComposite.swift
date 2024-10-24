//
//  TnTranscodingDecoder.swift
//  TnCameraBase
//
//  Created by Thinh Nguyen on 10/16/24.
//

import Foundation
import CoreImage
import CoreMedia
import TnIosBase

public class TnTranscodingDecoderComposite: TnLoggable {
    private let decoder: TnTranscodingDecoder
    private let adaptor: TnTranscodingDecoderAdaptor

    public init() {
        self.decoder = TnTranscodingDecoder(config: .init(/*realTime: true, */ /*enableHardware: true*/))
        self.adaptor = TnTranscodingDecoderAdaptor(decoder: decoder, isH264: false)
    }
    
    @discardableResult
    public func listen(sampleHandler: @escaping TnTranscodingImageHandler) -> Task<Void, Error> {
        Task { [self] in
            for await sampleBuffer in decoder.stream {
                if let imageBuffer = sampleBuffer.imageBuffer {
                    let ciImage = CIImage(cvImageBuffer: imageBuffer)
                    await sampleHandler(ciImage)
                }
            }
        }
    }
    
    public func decode(packet: Data) async throws {
        try await adaptor.decode(packet)
    }
    
    public func invalidate() {
        decoder.invalidate()
    }
}

public typealias TnTranscodingImageHandler = (CIImage) async -> Void
