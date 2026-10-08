//
//  ImageCache.swift
//  SWRPlayground
//
//  Created by Fadhil Ikhsanta's Personal on 30/09/26.
//

import UIKit

// MARK: - Protocol
protocol ImageCaching {
	func getImage(url: URL) -> UIImage?
	func insertImage(_ image: UIImage, url: URL)
}

final class ImageCache {
    // MARK: - Properties
    private let cache = NSCache<NSURL, UIImage>()
    
    // MARK: - Init
    init(
        imageCacheCountLimit: Int = 100,
        imageCacheTotalCostLimit: Int = 50 * 1024 * 1024
    ) {
        cache.countLimit = 100
        cache.totalCostLimit = imageCacheTotalCostLimit
    }
}

// MARK: - Conforms protocol
extension ImageCache: ImageCaching {
	func getImage(url: URL) -> UIImage? {
		let cacheKey = url as NSURL
		return cache.object(forKey: cacheKey)
	}
	
	func insertImage(_ image: UIImage, url: URL) {
		let cacheKey = url as NSURL
		cache.setObject(image, forKey: cacheKey)
	}
}
