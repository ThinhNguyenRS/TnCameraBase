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

    public init(config: TnTranscodingDecoderConfig) {
        self.decoder = TnTranscodingDecoder(config: config)
        self.adaptor = TnTranscodingDecoderAdaptor(decoder: decoder, isH264: false)
    }
    
    @discardableResult
    public func listen(sampleHandler: @escaping TnTranscodingImageHandler) -> Task<Void, Error> {
        Task { [self] in
            for await imageBuffer in decoder.imageStream {
                let ciImage = CIImage(cvImageBuffer: imageBuffer)
                await sampleHandler(ciImage)
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
