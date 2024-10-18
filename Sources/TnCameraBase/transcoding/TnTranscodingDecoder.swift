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

import Transcoding
public class TnTranscodingDecoderWrapper {
    private let decoder: VideoDecoder
    private var stream: AsyncStream<CMSampleBuffer>.Iterator
    private let adaptor: VideoDecoderAnnexBAdaptor

    private let decodingQueue = DispatchQueue(label: "TnTranscodingEncoder.decoding", qos: .background)
    private var decodingTask: Task<Void, Never>?

    public init() {
        decoder = VideoDecoder(config: .init(enableHardwareAcceleratedVideoDecoder: true, requireHardwareAcceleratedVideoDecoder: true))
        stream = decoder.decodedSampleBuffers.makeAsyncIterator()
        adaptor = VideoDecoderAnnexBAdaptor(videoDecoder: decoder, codec: .hevc)
    }
    
    public func listen(sampleHandler: @escaping (CIImage) -> Void) {
        decodingTask = Task { [weak self] in
            while true {
                guard let self else { return }
                guard let sampleBuffer = await stream.next() else {
                    try? await Task.sleep(nanoseconds: 1_000_000)
                    continue
                }
                
                if let imageBuffer = sampleBuffer.imageBuffer {
                    let ciImage = CIImage(cvImageBuffer: imageBuffer)
                    sampleHandler(ciImage)
                }
            }
        }
    }
    
    public func decode(packet: Data) {
        decodingQueue.async { [weak self] in
            guard let self else { return }
            adaptor.decode(packet)
        }
    }
}


public class TnTranscodingDecoderImpl: TnLoggable {
    private let decoder: TnTranscodingDecoderInternal
    private var stream: AsyncStream<CMSampleBuffer>.Iterator
    private let adaptor: TnTranscodingDecoderAdaptor

    public init() {
        self.decoder = TnTranscodingDecoderInternal(config: .init(realTime: true, maximizePowerEfficiency: true))
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
        try await adaptor.decode(packet)
    }
}

public typealias TnTranscodingImageHandler = (CIImage) async -> Void
