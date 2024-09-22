//
//  CameraDelegate.swift
//  tCamera
//
//  Created by Thinh Nguyen on 7/16/24.
//

import Foundation
import SwiftUI
import AVFoundation
import Photos
import TnIosBase

public class TnCameraCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate, TnLoggable {
    public let LOG_NAME = "TnCameraCaptureDelegate"

    private var photoData: Data? = nil
    private var photoLiveURL: URL?
    
    private let continuation: TnCameraPhotoOutputContinuation
    init(continuation: TnCameraPhotoOutputContinuation) {
        self.continuation = continuation
        super.init()
        
        logDebug("inited")
    }
    
    deinit {
        logDebug("de-inited")
    }

    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        logDebug("didFinishProcessingPhoto", "...")

        if let error {
            logError("didFinishProcessingPhoto", error.localizedDescription)
        } else {
            photoData = photo.fileDataRepresentation()
            logDebug("didFinishProcessingPhoto", "!")
        }
    }
    
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingLivePhotoToMovieFileAt outputFileURL: URL, duration: CMTime, photoDisplayTime: CMTime, resolvedSettings: AVCaptureResolvedPhotoSettings, error: (any Error)?) {
        logDebug("didFinishProcessingLivePhotoToMovieFileAt", "...")
        if let error {
            logError("didFinishProcessingLivePhotoToMovieFileAt", error.localizedDescription)
        } else {
            photoLiveURL = outputFileURL
            logDebug("didFinishProcessingLivePhotoToMovieFileAt", "!")
        }
    }

    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: (any Error)?) {
        logDebug("didFinishCaptureFor", "...")

        // If an error occurs, resume the continuation by throwing an error, and return.
        if let error {
            logError("didFinishCaptureFor", error.localizedDescription)
            continuation.resume(throwing: TnCameraPhotoOutputError.general(error: error.localizedDescription))
            return
        }
        
        // If the app captures no photo data, resume the continuation by throwing an error, and return.
        guard let photoData else {
            logError("didFinishCaptureFor", "noData")
            continuation.resume(throwing: TnCameraPhotoOutputError.noData)
            return
        }
        
        logDebug("didFinishCaptureFor", "!")

        // Resume the continuation by returning the captured photo.
        let output = TnCameraPhotoOutput(photoData: photoData, photoLiveURL: photoLiveURL)
        continuation.resume(returning: output)
    }
}


//public class TnCameraCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate, TnLoggable {
//    public let LOG_NAME = "TnCameraCaptureDelegate"
//    private var capturedImageData: Data? = nil
//    
//    let continuation: TnCameraPhotoOutputContinuation
//    init(continuation: TnCameraPhotoOutputContinuation) {
//        self.continuation = continuation
//    }
//    
//    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
//        logDebug("didFinishProcessingPhoto", "...")
//
//        if let error {
//            continuation.resume(throwing: TnCameraPhotoOutputError.general(name: "didFinishProcessingPhoto", error: error.localizedDescription))
//        } else {
//            if photo.depthData != nil {
//                logDebug("didFinishProcessingPhoto", "has depth")
//            }
//            
//            if photo.portraitEffectsMatte != nil {
//                logDebug("didFinishProcessingPhoto", "has portrait")
//            }
//            
//            if let imageData = photo.fileDataRepresentation() {
//                self.capturedImageData = imageData
//                if !output.isLivePhotoCaptureEnabled {
//                    saveImageToGallery()
//                }
//            } else {
//                continuation.resume(throwing: TnCameraPhotoOutputError.general(name: "didFinishProcessingPhoto", error: "cannot fetch image"))
//            }
//        }        
//        logDebug("didFinishProcessingPhoto", "!")
//    }
//    
//    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingLivePhotoToMovieFileAt outputFileURL: URL, duration: CMTime, photoDisplayTime: CMTime, resolvedSettings: AVCaptureResolvedPhotoSettings, error: (any Error)?) {
//        logDebug("didFinishProcessingLivePhotoToMovieFileAt", "...")
//        
//        if let error {
//            continuation.resume(throwing: TnCameraPhotoOutputError.general(name: "didFinishProcessingLivePhotoToMovieFileAt", error: error.localizedDescription))
//        } else {
//            // Save Live Photo.
//            saveLivephotoToGallery(outputFileURL)
//        }
//        logDebug("didFinishProcessingLivePhotoToMovieFileAt", "!")
//    }
//    
//    func saveImageToGallery() {
//        logDebug("saveImageToGallery", "...")
//
//        guard let capturedImageData = self.capturedImageData, let capturedImage = UIImage(data: capturedImageData) else {
//            continuation.resume(throwing: TnCameraPhotoOutputError.general(name: "saveImageToGallery", error: "cannot fetch image"))
//            return
//        }
//
//        PHPhotoLibrary.shared().performChanges(
//            {
//                PHAssetChangeRequest.creationRequestForAsset(from: capturedImage)
//            },
//            completionHandler: { [self] success, error in
//                if success {
//                    continuation.resume(returning: .init(imageData: capturedImageData))
//                } else if let error {
//                    continuation.resume(throwing: TnCameraPhotoOutputError.general(name: "saveImageToGallery", error: error.localizedDescription))
//                } else {
//                    continuation.resume(throwing: TnCameraPhotoOutputError.general(name: "saveImageToGallery", error: "unknown"))
//                }
//                logDebug("saveImageToGallery", "!")
//            }
//        )
//    }
//    
//    func saveLivephotoToGallery(_ outputFileURL: URL) {
//        logDebug("saveLivephotoToGallery", "...")
//
//        PHPhotoLibrary.requestAuthorization { [self] status in
//            guard status == .authorized else {
//                continuation.resume(throwing: TnCameraPhotoOutputError.general(name: "saveLivephotoToGallery", error: "unauthorized"))
//                return
//            }
//        }
//        
//        guard let capturedImageData = self.capturedImageData else {
//            continuation.resume(throwing: TnCameraPhotoOutputError.general(name: "saveImageToGallery", error: "cannot fetch image"))
//            return
//        }
//        
//        PHPhotoLibrary.shared().performChanges({
//            // Add the captured photo's file data as the main resource for the Photos asset.
//            let creationRequest = PHAssetCreationRequest.forAsset()
//            creationRequest.addResource(with: .photo, data: capturedImageData, options: nil)
//            
//            // Add the movie file URL as the Live Photo's paired video resource.
//            let options = PHAssetResourceCreationOptions()
//            options.shouldMoveFile = true
//            creationRequest.addResource(with: .pairedVideo, fileURL: outputFileURL, options: options)
//        }) { [self] success, error in
//            // Handle completion.
//            if success {
//                continuation.resume(returning: .init(livePhotoMovieURL: outputFileURL))
//            } else if let error {
//                continuation.resume(throwing: TnCameraPhotoOutputError.general(name: "saveImageToGallery", error: error.localizedDescription))
//            } else {
//                continuation.resume(throwing: TnCameraPhotoOutputError.general(name: "saveLivephotoToGallery.capturedImageData", error: "unknown"))
//            }
//            logDebug("saveLivephotoToGallery", "!")
//        }
//    }
//}
