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
    
    private var inCounter = 0
    private var outCounter = 0
    
    private let encodingQueue = DispatchQueue(label: "TnTranscodingEncoder.encoding", qos: .background)
    private var transportingTask: Task<Void, Never>?

    public init(sendingName: [String] = ["streaming"]) {
        self.encoder = VideoEncoder(config: .ultraLowLatency)
        self.adaptor = VideoEncoderAnnexBAdaptor(videoEncoder: encoder)
        self.stream = adaptor.annexBData.makeAsyncIterator()

    }
    
    public func listen(packetHandler: @escaping (Data) -> Void) {
        self.transportingTask = Task { [weak self] in
            while true {
                guard let self else { return }
                guard let packet = await stream.next() else {
                    try? await Task.sleep(nanoseconds: 1_000_000)
                    continue
                }
                packetHandler(packet)
                outCounter += 1
                logDebug("out", outCounter, packet.count)
            }
        }
    }
    
    public func encode(_ ciImage: CIImage?) {
        encodingQueue.async { [weak self] in
            guard let self else { return }
            
            if let pixelBuffer = ciImage?.pixelBuffer {
                inCounter += 1
                encoder.encode(pixelBuffer)
                logDebug("in", inCounter)
            }
        }
    }
}
