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
    private var stream: AsyncStream<CMSampleBuffer>.Iterator
    private let adaptor: TnTranscodingDecoderAdaptor

    public init() {
        self.decoder = TnTranscodingDecoder(config: .init(enableHardware: true))
        self.stream = decoder.makeStreamIterator()
        self.adaptor = TnTranscodingDecoderAdaptor(decoder: decoder, isH264: false)
    }
    
    public func listen(sampleHandler: @escaping TnTranscodingImageHandler) {
        Task { [self] in
            while let sampleBuffer = await stream.next() {
                if let imageBuffer = sampleBuffer.imageBuffer {
                    let ciImage = CIImage(cvImageBuffer: imageBuffer)
                    await sampleHandler(ciImage)
                }
            }
        }
    }
    
    public func decode(packet: Data) async throws {
        Task {
            try await adaptor.decode(packet)
        }
    }
}

public typealias TnTranscodingImageHandler = (CIImage) async -> Void
