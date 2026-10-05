//
//  APIClientError.swift
//  Product Catalog v3
//
//  Created by Fadhil Ikhsanta's Personal on 25/09/26.
//

import Foundation

enum APIClientError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpStatus(Int)

	var errorDescription: String? {
		return switch self {
		case .invalidURL:
			"URL API tidak valid."
		case .invalidResponse:
			"Respons server tidak dapat dibaca."
		case let .httpStatus(statusCode):
			"Server mengembalikan status HTTP \(statusCode)."
		}
	}
}
