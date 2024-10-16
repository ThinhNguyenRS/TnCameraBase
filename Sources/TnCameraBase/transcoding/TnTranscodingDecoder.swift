//
//  TnTranscodingDecoder.swift
//  TnCameraBase
//
//  Created by Thinh Nguyen on 10/16/24.
//

import Foundation
import CoreImage
import Transcoding
import TnIosBase
import CoreMedia

public class TnTranscodingDecoder {
    private let decoder: VideoDecoder
    private var stream: AsyncStream<CMSampleBuffer>.Iterator
    private let adaptor: VideoDecoderAnnexBAdaptor

    private let decodingQueue = DispatchQueue(label: "TnTranscodingEncoder.decoding", qos: .background)
    private var decodingTask: Task<Void, Never>?

    public init() {
        decoder = VideoDecoder(config: .init())
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
