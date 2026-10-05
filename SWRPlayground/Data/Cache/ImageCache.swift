//
//  ImageCache.swift
//  Product Catalog v3
//
//  Created by Fadhil Ikhsanta's Personal on 30/09/26.
//

import UIKit

protocol ImageCaching {
	func getImage(url: URL) -> UIImage?
	func insertImage(_ image: UIImage, url: URL)
}

final class ImageCache: ImageCaching {
	private let cache = NSCache<NSURL, UIImage>()
	
	init(
		imageCacheCountLimit: Int = 100,
		imageCacheTotalCostLimit: Int = 50 * 1024 * 1024
	) {
		cache.countLimit = 100
		cache.totalCostLimit = imageCacheTotalCostLimit
	}
	
	func getImage(url: URL) -> UIImage? {
		let cacheKey = url as NSURL
		return cache.object(forKey: cacheKey)
	}
	
	func insertImage(_ image: UIImage, url: URL) {
		let cacheKey = url as NSURL
		cache.setObject(image, forKey: cacheKey)
	}
}
