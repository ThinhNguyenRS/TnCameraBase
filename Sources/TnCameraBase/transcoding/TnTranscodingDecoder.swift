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

    private let mainQueue: DispatchQueue
    private let outputQueue: DispatchQueue

    public init() {
        self.decoder = TnTranscodingDecoderInternal(config: .init())
        self.stream = decoder.makeStreamIterator()
        self.adaptor = TnTranscodingDecoderAdaptor(decoder: decoder, isH264: false)
        self.mainQueue = DispatchQueue(label: "\(Self.self).main", qos: .background)
        self.outputQueue = DispatchQueue(label: "\(Self.self).output", qos: .background)
    }
    
//    public func listen(sampleHandler: @escaping TnTranscodingImageHandler) {
//        Task { [weak self] in
//            while true {
//                guard let self else { return }
//                guard let sampleBuffer = await stream.next() else {
//                    try? await Task.sleep(nanoseconds: 1_000_000)
//                    continue
//                }
//                
//                if let imageBuffer = sampleBuffer.imageBuffer {
//                    let ciImage = CIImage(cvImageBuffer: imageBuffer)
//                    await sampleHandler(ciImage)
//                }
//            }
//        }
//    }
    
    public func decode(packet: Data, imageHandler: @escaping TnTranscodingImageHandler) async throws {
        mainQueue.async { [self] in
            Task {
                logDebug("decode")
                try await adaptor.decode(packet)
            }
        }
        
        outputQueue.async { [self] in
            Task {
                while let sampleBuffer = await stream.next(), let imageBuffer = sampleBuffer.imageBuffer {
                    logDebug("deliver image")
                    let ciImage = CIImage(cvImageBuffer: imageBuffer)
                    await imageHandler(ciImage)
                }
            }
        }
    }
}

public typealias TnTranscodingImageHandler = (CIImage) async -> Void
