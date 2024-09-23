//
//  TnCameraOutput.swift
//  TnCameraBase
//
//  Created by Thinh Nguyen on 9/20/24.
//

import Foundation

public struct TnCameraPhotoOutput {
    public let photoData: Data
    public let photoLiveURL: URL?

    public init(photoData: Data, photoLiveURL: URL?) {
        self.photoData = photoData
        self.photoLiveURL = photoLiveURL
    }
}

public typealias TnCameraPhotoOutputContinuation = CheckedContinuation<TnCameraPhotoOutput, Error>

public typealias TnCameraPhotoOutputCompletion = (TnCameraPhotoOutput) -> Void
