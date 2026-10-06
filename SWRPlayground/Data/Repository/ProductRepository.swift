//
//  ProductRepository.swift
//  SWRPlayground
//
//  Created by Fadhil Ikhsanta's Personal on 25/09/26.
//

import Foundation

protocol ProductRepository {
	func observeProductItemsByPage(
		for request: PageRequest
	) -> AsyncThrowingStream<ProductItemsByPage, Error>
	func observeProductDetail(id: Int) -> AsyncThrowingStream<ProductDetail, Error>
}

final class DefaultProductRepository: ProductRepository {
    private let apiClient: ProductAPIClient
    private let cache: ProductCaching

    init(apiClient: ProductAPIClient, cache: ProductCaching) {
        self.apiClient = apiClient
        self.cache = cache
    }

    func observeProductItemsByPage(
        for request: PageRequest
    ) -> AsyncThrowingStream<ProductItemsByPage, Error> {
		AsyncThrowingStream { continuation in
            let task = Task { [weak self] in
				guard let self else { throw CancellationError() }
				
				if let cachedPage = cache.getProductItemsByPage(for: request) {
					continuation.yield(cachedPage)
                }

                do {
					let networkPage = try await apiClient.fetchProductList(request: request)
                    try Task.checkCancellation()
					
					let domainPage = networkPage.toDomain()
					
					cache.insertProductItemsByPage(domainPage, for: request)
					continuation.yield(domainPage)
                    continuation.finish()
                } catch is CancellationError {
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }
	
	func observeProductDetail(id: Int) -> AsyncThrowingStream<ProductDetail, Error> {
		AsyncThrowingStream { continuation in
			let task = Task { [weak self] in
				guard let self else { throw CancellationError() }
				
				if let cachedPage = cache.getProductDetail(id: id) {
					continuation.yield(cachedPage)
				}
				
				do {
					let product = try await apiClient.fetchProductDetail(id: id)
					try Task.checkCancellation()
					
					let domainProduct = product.toDomain()
					
					cache.insertProductDetail(domainProduct)
					continuation.yield(domainProduct)
					continuation.finish()
				} catch is CancellationError {
					continuation.finish()
				} catch {
					continuation.finish(throwing: error)
				}
			}
			
			continuation.onTermination = { @Sendable _ in
				task.cancel()
			}
		}
	}
}
