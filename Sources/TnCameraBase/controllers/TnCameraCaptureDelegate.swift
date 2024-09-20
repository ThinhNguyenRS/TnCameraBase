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
    private var capturedImageData: Data? = nil
    
    let continuation: TnCameraPhotoOutputContinuation
    init(continuation: TnCameraPhotoOutputContinuation) {
        self.continuation = continuation
    }
    
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error {
            continuation.resume(throwing: TnCameraPhotoOutputError.general(name: "didFinishProcessingPhoto", error: error.localizedDescription))
            return
        }
        
        if photo.depthData != nil {
            logDebug("didFinishProcessingPhoto", "has depth")
        }
        
        if photo.portraitEffectsMatte != nil {
            logDebug("didFinishProcessingPhoto", "has portrait")
        }
        
        if let imageData = photo.fileDataRepresentation() {
            self.capturedImageData = imageData
            if !output.isLivePhotoCaptureEnabled {
                saveImageToGallery()
            }
        } else {
            continuation.resume(throwing: TnCameraPhotoOutputError.general(name: "didFinishProcessingPhoto", error: "cannot fetch image"))
        }
    }
    
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingLivePhotoToMovieFileAt outputFileURL: URL, duration: CMTime, photoDisplayTime: CMTime, resolvedSettings: AVCaptureResolvedPhotoSettings, error: (any Error)?) {
        logDebug("didFinishProcessingLivePhotoToMovieFileAt", outputFileURL.absoluteString)
        
        if let error {
            continuation.resume(throwing: TnCameraPhotoOutputError.general(name: "didFinishProcessingLivePhotoToMovieFileAt", error: error.localizedDescription))
            return
        }
        
        // Save Live Photo.
        saveLivephotoToGallery(outputFileURL)
    }
    
    func saveImageToGallery() {
        guard let capturedImageData = self.capturedImageData, let capturedImage = UIImage(data: capturedImageData) else {
            continuation.resume(throwing: TnCameraPhotoOutputError.general(name: "saveImageToGallery", error: "cannot fetch image"))
            return
        }

        PHPhotoLibrary.shared().performChanges(
            {
                PHAssetChangeRequest.creationRequestForAsset(from: capturedImage)
            },
            completionHandler: { [self] success, error in
                if success {
                    logDebug("Image saved to gallery.")
                    continuation.resume(with: .success(.init(imageData: capturedImageData)))
                } else if let error {
                    continuation.resume(throwing: TnCameraPhotoOutputError.general(name: "saveImageToGallery", error: error.localizedDescription))
                } else {
                    continuation.resume(throwing: TnCameraPhotoOutputError.general(name: "saveImageToGallery", error: "unknown"))
                }
            }
        )
    }
    
    func saveLivephotoToGallery(_ outputFileURL: URL) {
        PHPhotoLibrary.requestAuthorization { [self] status in
            guard status == .authorized else {
                continuation.resume(throwing: TnCameraPhotoOutputError.general(name: "saveLivephotoToGallery", error: "unauthorized"))
                return
            }
        }
        
        guard let capturedImageData = self.capturedImageData else {
            continuation.resume(throwing: TnCameraPhotoOutputError.general(name: "saveImageToGallery", error: "cannot fetch image"))
            return
        }

        logDebug("saveLivephotoToGallery", "...")
        
        PHPhotoLibrary.shared().performChanges({
            // Add the captured photo's file data as the main resource for the Photos asset.
            let creationRequest = PHAssetCreationRequest.forAsset()
            creationRequest.addResource(with: .photo, data: capturedImageData, options: nil)
            
            // Add the movie file URL as the Live Photo's paired video resource.
            let options = PHAssetResourceCreationOptions()
            options.shouldMoveFile = true
            creationRequest.addResource(with: .pairedVideo, fileURL: outputFileURL, options: options)
        }) { [self] success, error in
            // Handle completion.
            if success {
                logDebug("saveLivephotoToGallery", "!")
                continuation.resume(with: .success(.init(livePhotoMovieURL: outputFileURL)))
                return
            }

            if let error {
                continuation.resume(throwing: TnCameraPhotoOutputError.general(name: "saveImageToGallery", error: error.localizedDescription))
                return
            }
            
            continuation.resume(throwing: TnCameraPhotoOutputError.general(name: "saveLivephotoToGallery.capturedImageData", error: "unknown"))
        }
    }
}
