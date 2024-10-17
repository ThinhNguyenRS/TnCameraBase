//
//  TnTranscodingDecoderAdaptor.swift
//  TnCameraBase
//
//  Created by Thinh Nguyen on 10/17/24.
//

import Foundation
import VideoToolbox
import TnIosBase

public final class TnTranscodingDecoderAdaptor {
    private let decoder: TnTranscodingDecoderInternal
    private let isH264: Bool
    private var vps: Data?
    private var sps: Data?
    private var pps: Data?

    public init(decoder: TnTranscodingDecoderInternal, isH264: Bool = false) {
        self.decoder = decoder
        self.isH264 = isH264
    }

    public func decode(_ data: Data) async throws {
        if isH264 {
            try await decodeH264(data)
        } else {
            try await decodeHEVC(data)
        }
    }

    private func decodeH264(_ data: Data) async throws {
        for nalu in data.split(separator: H264NALU.startCode).map({ H264NALU(data: Data($0)) }) {
            if nalu.isSPS {
                sps = nalu.data
            } else if nalu.isPPS {
                pps = nalu.data
            } else if nalu.isPFrame || nalu.isIFrame {
                if nalu.isIFrame, let sps, let pps {
                    let formatDescription = try CMVideoFormatDescription(h264ParameterSets: [sps, pps])
                    try decoder.setFormatDescription(formatDescription)
                }
                try await decodeAVCCFrame(nalu.avcc)
            }
        }
    }

    private func decodeHEVC(_ data: Data) async throws {
        for nalu in data.split(separator: HEVCNALU.startCode).map({ HEVCNALU(data: Data($0)) }) {
            if nalu.isVPS {
                vps = nalu.data
            } else if nalu.isSPS {
                sps = nalu.data
            } else if nalu.isPPS {
                pps = nalu.data
            } else if nalu.isPFrame || nalu.isIFrame {
                if nalu.isIFrame, let vps, let sps, let pps {
                    let formatDescription = try CMVideoFormatDescription(hevcParameterSets: [vps, sps, pps])
                    try decoder.setFormatDescription(formatDescription)
                }
                try await decodeAVCCFrame(nalu.avcc)
            }
        }
    }

    private func decodeAVCCFrame(_ data: Data) async throws {
        guard let formatDescription = decoder.formatDescription else {
            throw TnTranscodingError.general(message: "No format description")
        }
        
        var data = data
        var sampleBuffer: CMSampleBuffer!
        
        try data.withUnsafeMutableBytes { pointer in
            let dataBuffer = try CMBlockBuffer(buffer: pointer, allocator: kCFAllocatorNull)
            
            sampleBuffer = try CMSampleBuffer(
                dataBuffer: dataBuffer,
                formatDescription: formatDescription,
                numSamples: 1,
                sampleTimings: [],
                sampleSizes: []
            )
        }

        try await decoder.decode(sampleBuffer)
    }
}
