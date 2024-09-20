//
//  TnCameraOutput.swift
//  TnCameraBase
//
//  Created by Thinh Nguyen on 9/20/24.
//

import Foundation

public struct TnCameraPhotoOutput {
    public let imageData: Data?
    public let livePhotoMovieURL: URL?
    
    public init(imageData: Data) {
        self.imageData = imageData
        self.livePhotoMovieURL = nil
    }

    public init(livePhotoMovieURL: URL) {
        self.imageData = nil
        self.livePhotoMovieURL = livePhotoMovieURL
    }
}

public enum TnCameraPhotoOutputError: Error {
    case general(name: String, error: String)
}

public typealias TnCameraPhotoOutputContinuation = CheckedContinuation<TnCameraPhotoOutput, Error>

public typealias TnCameraPhotoOutputCompletion = (TnCameraPhotoOutput) -> Void
