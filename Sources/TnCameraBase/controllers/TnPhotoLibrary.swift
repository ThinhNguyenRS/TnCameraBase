//
//  File.swift
//  TnCameraBase
//
//  Created by Thinh Nguyen on 9/22/24.
//

import Foundation
import Photos
import UIKit
import TnIosBase

public struct TnCameraAlbum: Equatable {
    let name: String
    let startDate: Date?
    let endDate: Date?
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.name == rhs.name
    }
    
    init(name: String, startDate: Date?, endDate: Date?) {
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
    }
    
    init(_ assetAlbum: PHAssetCollection) {
        self.init(name: assetAlbum.localizedTitle ?? "", startDate: assetAlbum.startDate, endDate: assetAlbum.endDate)
    }
}

public actor TnPhotoLibrary: TnLoggable {
    public func getAlbums() -> [String] {
        var retAlbums: [String] = []
        
        let topAlbums = PHCollectionList.fetchTopLevelUserCollections(with: nil)
        topAlbums.enumerateObjects { album, _, _ in
            if let assetAlbum = album as? PHAssetCollection {
                retAlbums.append(assetAlbum.localizedTitle ?? "")
            }
        }
        
        return retAlbums
    }
    
    public func getAlbum(name: String) -> PHAssetCollection? {
        var retAssetAlbum: PHAssetCollection? = nil
        
        let topAlbums = PHCollectionList.fetchTopLevelUserCollections(with: nil)
        for i in 0..<topAlbums.count {
            if let assetAlbum = topAlbums.object(at: i) as? PHAssetCollection {
                if assetAlbum.localizedTitle == name {
                    retAssetAlbum = assetAlbum
                    break
                }
            }
        }
        
        return retAssetAlbum
    }
    
    public func createAlbum(name: String) async throws -> PHAssetCollection {
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: name)
        }
        guard let createdAlbum = getAlbum(name: name) else {
            throw TnAppError.from("Cannot create album: \(name)")
        }
        return createdAlbum
    }
    
    public func getOrCreateAlbum(name: String) async throws -> PHAssetCollection {
        var album = getAlbum(name: name)
        if album == nil {
            album = try await createAlbum(name: name)
        }
        return album!
    }
    
    public func addPhoto(image: UIImage, album: PHAssetCollection? = nil) async throws {
        // Add the asset to the photo library.
        try await PHPhotoLibrary.shared().performChanges {
            let creationRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
            if let album {
                if let addAssetRequest = PHAssetCollectionChangeRequest(for: album) {
                    addAssetRequest.addAssets([creationRequest.placeholderForCreatedAsset!] as NSArray)
                }
            }
        }
    }
}

extension TnPhotoLibrary {
    public func addPhoto(imageData: Data, album: PHAssetCollection? = nil) async throws {
        guard let image = UIImage(data: imageData) else {
            throw TnAppError.from("Cannot create image")
        }
        try await addPhoto(image: image, album: album)
    }
    
    public func addPhoto(imageData: Data, albumName: String? = nil) async throws {
        guard let image = UIImage(data: imageData) else {
            throw TnAppError.from("Cannot create image")
        }

        var album: PHAssetCollection? = nil
        if let albumName {
            album = try await getOrCreateAlbum(name: albumName)
        }
        
        try await addPhoto(image: image, album: album)
    }
}
