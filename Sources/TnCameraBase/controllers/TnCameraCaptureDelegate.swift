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
    public let LOG_NAME = "CameraCaptureDelegate"
    
    private let completion: (UIImage) -> Void
    
    var capturedImageData: Data? = nil

    init(completion: @escaping (UIImage) -> Void) {
        self.completion = completion
    }
    
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error {
            logError("didFinishProcessingPhoto error", error)
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
            logError("didFinishProcessingPhoto", "cannot fetch image")
        }
    }
    
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingLivePhotoToMovieFileAt outputFileURL: URL, duration: CMTime, photoDisplayTime: CMTime, resolvedSettings: AVCaptureResolvedPhotoSettings, error: (any Error)?) {
        logDebug("didFinishProcessingLivePhotoToMovieFileAt", outputFileURL.absoluteString)
        
        if let error {
            logError("didFinishProcessingLivePhotoToMovieFileAt error", error.localizedDescription);
            return
        }
        
        // Save Live Photo.
        saveLivephotoToGallery(outputFileURL)
    }
    
    func saveImageToGallery() {
        guard let capturedImageData = self.capturedImageData, let capturedImage = UIImage(data: capturedImageData) else {
            return
        }

        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: capturedImage)
        } completionHandler: { [self] success, error in
            if success {
                TnLogger.debug("CameraDelegate", "Image saved to gallery.")
                completion(capturedImage)
            } else if let error {
                TnLogger.error("CameraDelegate", "Saving image to gallery", error)
            }
        }
    }
    
    func saveLivephotoToGallery(_ outputFileURL: URL) {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else { 
                return
            }
        }
        
        guard let capturedImageData = self.capturedImageData else {
            return
        }

        logDebug("didFinishProcessingLivePhotoToMovieFileAt, saving")
        
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
            if let error {
                logDebug("didFinishProcessingLivePhotoToMovieFileAt", "error", error.localizedDescription)
            }
            
            if success {
                logDebug("didFinishProcessingLivePhotoToMovieFileAt", "saved")
            }
        }
    }
}
