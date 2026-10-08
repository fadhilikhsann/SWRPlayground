//
//  MockProductAPIClient.swift
//  SWRPlayground
//
//  Created by Fadhil Ikhsanta's Personal on 06/10/26.
//

@testable import SWRPlayground

final class MockProductAPIClient: ProductAPIClient {
    var fetchProductListCallCount: Int = 0
    var fetchProductDetailCallCount: Int = 0
    
    var fetchProductListResult: Result<ProductResponseDTO, Error>?
    var fetchProductDetailResult: Result<ProductDetailDTO, Error>?
    
    func fetchProductList(request: PageRequest) async throws -> ProductResponseDTO {
        fetchProductListCallCount += 1
        
        switch fetchProductListResult {
        case let .success(value):
            return value
        case let .failure(error):
            throw error
        case nil:
            throw MockLocalizedError(errorDescription: "No result.")
        }
    }
    
    func fetchProductDetail(id: Int) async throws -> ProductDetailDTO {
        fetchProductDetailCallCount += 1
        
        switch fetchProductDetailResult {
        case let .success(value):
            return value
        case let .failure(error):
            throw error
        case nil:
            throw MockLocalizedError(errorDescription: "No result.")
        }
    }
}
