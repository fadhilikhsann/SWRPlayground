//
//  ImageLoaderError.swift
//  Product Catalog v3
//
//  Created by Fadhil Ikhsanta's Personal on 27/09/26.
//

import Foundation

enum ImageLoaderError: LocalizedError {
    case invalidResponse
    case httpStatus(Int)
    case invalidImageData

	var errorDescription: String? {
		return switch self {
		case .invalidResponse:
			"Invalid image response."
		case let .httpStatus(statusCode):
			"HTTP status code error: \(statusCode)."
		case .invalidImageData:
			"Can't read image data."
		}
	}
}
