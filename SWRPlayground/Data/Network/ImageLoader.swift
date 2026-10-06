//
//  ImageLoader.swift
//  SWRPlayground
//
//  Created by Fadhil Ikhsanta's Personal on 25/09/26.
//

import UIKit

protocol ImageLoading {
	func loadImage(from url: URL) async throws -> UIImage
}

final class ImageLoader {
	private let session: URLSession
	private let cache: ImageCaching
	init(
		session: URLSession = .shared,
		cache: ImageCaching
	) {
		self.session = session
		self.cache = cache
	}
}

extension ImageLoader: ImageLoading {
    /// Cache first
	func loadImage(from url: URL) async throws -> UIImage {
		try Task.checkCancellation()
		
		if let cachedImage = cache.getImage(url: url) {
			return cachedImage
		}
		
		let image = try await fetchImage(from: url)
		try Task.checkCancellation()
		cache.insertImage(image, url: url)
		return image
	}
}

extension ImageLoader {
    private func fetchImage(from url: URL) async throws -> UIImage {
        let (data, response) = try await session.data(from: url)
        try Task.checkCancellation()

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ImageLoaderError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw ImageLoaderError.httpStatus(httpResponse.statusCode)
        }
        guard let image = UIImage(data: data) else {
            throw ImageLoaderError.invalidImageData
        }
        return image
    }
}
