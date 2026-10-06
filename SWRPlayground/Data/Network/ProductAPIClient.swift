//
//  ProductAPIClient.swift
//  SWRPlayground
//
//  Created by Fadhil Ikhsanta's Personal on 25/09/26.
//

import Foundation

protocol ProductAPIClient {
    func fetchProductList(request: PageRequest) async throws -> ProductResponseDTO
	func fetchProductDetail(id: Int) async throws -> ProductDetailDTO
}

final class DefaultProductAPIClient: ProductAPIClient {
    private let host = "https://www.dummyjson.com"
    private let path = "/products"
    
    private let session: URLSession
    private let decoder: JSONDecoder

    init(
        session: URLSession = .shared,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.session = session
        self.decoder = decoder
    }

    func fetchProductList(request: PageRequest) async throws -> ProductResponseDTO {
        guard var components = URLComponents(string: "\(host)\(path)") else {
            throw APIClientError.invalidURL
        }

        components.queryItems = [
            URLQueryItem(name: "limit", value: String(request.limit)),
            URLQueryItem(name: "skip", value: String(request.skip)),
            URLQueryItem(
                name: "select",
                value: "title,category,price,thumbnail"
            )
        ]

        guard let url = components.url else {
            throw APIClientError.invalidURL
        }

        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIClientError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIClientError.httpStatus(httpResponse.statusCode)
        }

        return try decoder.decode(ProductResponseDTO.self, from: data)
    }
	
	func fetchProductDetail(id: Int) async throws -> ProductDetailDTO {
		guard var components = URLComponents(string: "\(host)\(path)/\(id)") else {
			throw APIClientError.invalidURL
		}
		
		components.queryItems = [
			URLQueryItem(
				name: "select",
				value: "title,category,price,description,images"
			)
		]
		
		guard let url = components.url else {
			throw APIClientError.invalidURL
		}
		
		let (data, response) = try await session.data(from: url)
		guard let httpResponse = response as? HTTPURLResponse else {
			throw APIClientError.invalidResponse
		}
		guard (200...299).contains(httpResponse.statusCode) else {
			throw APIClientError.httpStatus(httpResponse.statusCode)
		}
		
		return try decoder.decode(ProductDetailDTO.self, from: data)
	}
}
