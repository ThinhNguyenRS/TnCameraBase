//
//  TnTranscodingEncoder.swift
//  TnCameraBase
//
//  Created by Thinh Nguyen on 10/16/24.
//

import Foundation
import CoreImage
import Transcoding
import TnIosBase

public class TnTranscodingEncoder: TnLoggable {
    private let encoder: VideoEncoder
    private let adaptor: VideoEncoderAnnexBAdaptor
    private var stream: AsyncStream<Data>.Iterator
    
    private let encodingQueue = DispatchQueue(label: "TnTranscodingEncoder.encoding", qos: .background)
    private var transportingTask: Task<Void, Never>?

    public init(sendingName: [String] = ["streaming"]) {
        self.encoder = VideoEncoder(config: .ultraLowLatency)
        self.adaptor = VideoEncoderAnnexBAdaptor(videoEncoder: encoder)
        self.stream = adaptor.annexBData.makeAsyncIterator()

    }
    
    public func listen(packetHandler: @escaping (Data) -> Void) {
        self.transportingTask = Task { [self] in
            while true {
                guard let packet = await stream.next() else {
                    try? await Task.sleep(nanoseconds: 1_000_000)
                    continue
                }
                packetHandler(packet)
            }
        }
    }
    
    public func encode(_ ciImage: CIImage?) {
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
