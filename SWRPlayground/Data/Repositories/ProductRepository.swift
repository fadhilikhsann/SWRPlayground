//
//  ProductRepository.swift
//  SWRPlayground
//
//  Created by Fadhil Ikhsanta's Personal on 25/09/26.
//

import Foundation

// MARK: - Protocol
protocol ProductRepository {
	func observeProductItemsByPage(
		for request: PageRequest
	) -> AsyncThrowingStream<ProductItemsByPage, Error>
	func observeProductDetail(id: Int) -> AsyncThrowingStream<ProductDetail, Error>
}

final class DefaultProductRepository {
    // MARK: - Properties
    private let apiClient: ProductAPIClient
    private let cache: ProductCaching
    
    // MARK: - Init
    init(apiClient: ProductAPIClient, cache: ProductCaching) {
        self.apiClient = apiClient
        self.cache = cache
    }
}

// MARK: - Conforms protocol
extension DefaultProductRepository: ProductRepository {
    func observeProductItemsByPage(
        for request: PageRequest
    ) -> AsyncThrowingStream<ProductItemsByPage, Error> {
        let (stream, continuation) = AsyncThrowingStream<ProductItemsByPage, Error>.makeStream()
        
        let task = Task { [weak self] in
            guard let self else {
                continuation.finish(throwing: CancellationError())
                return
            }
            
            let cachedPage = await cache.getProductItemsByPage(for: request)
            if let cachedPage {
                continuation.yield(cachedPage)
            }
            
            do {
                let networkPage = try await apiClient.fetchProductList(request: request)
                try Task.checkCancellation()
                
                let domainPage = networkPage.toDomain()
                
                await cache.insertProductItemsByPage(domainPage, for: request)
                if cachedPage != domainPage {
                    continuation.yield(domainPage)
                }
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
        
        return stream
    }
	
    func observeProductDetail(id: Int) -> AsyncThrowingStream<ProductDetail, Error> {
        let (stream, continuation) = AsyncThrowingStream<ProductDetail, Error>.makeStream()
        
        let task = Task { [weak self] in
            guard let self else {
                continuation.finish(throwing: CancellationError())
                return
            }
            
            let cachedProduct = await cache.getProductDetail(id: id)
            if let cachedProduct {
                continuation.yield(cachedProduct)
            }
            
            do {
                let product = try await apiClient.fetchProductDetail(id: id)
                try Task.checkCancellation()
                
                let domainProduct = product.toDomain()
                
                await cache.insertProductDetail(domainProduct)
                if cachedProduct != domainProduct {
                    continuation.yield(domainProduct)
                }
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
        
        return stream
    }
}
