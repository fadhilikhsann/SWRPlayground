//
//  MockProductRepository.swift
//  SWRPlayground
//
//  Created by Fadhil Ikhsanta's Personal on 07/10/26.
//

@testable import SWRPlayground

final class MockProductRepository: ProductRepository {
    var observeProductItemsByPageCallCount = 0
    var observeProductItemsByPageResult: AsyncThrowingStream<ProductItemsByPage, Error>?
    
    var observeProductDetailCallCount = 0
    var observeProductDetailResult: AsyncThrowingStream<ProductDetail, Error>?
    
    func observeProductItemsByPage(for request: PageRequest) -> AsyncThrowingStream<ProductItemsByPage, Error> {
        observeProductItemsByPageCallCount += 1
        return observeProductItemsByPageResult ?? AsyncThrowingStream {
            $0.finish(throwing: MockLocalizedError(errorDescription: "No result."))
        }
    }
    
    func observeProductDetail(id: Int) -> AsyncThrowingStream<ProductDetail, Error> {
        observeProductDetailCallCount += 1
        return observeProductDetailResult ?? AsyncThrowingStream {
            $0.finish(throwing: MockLocalizedError(errorDescription: "No result."))
        }
    }
}
