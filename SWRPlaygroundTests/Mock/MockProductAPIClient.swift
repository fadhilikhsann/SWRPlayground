//
//  MockProductAPIClient.swift
//  SWRPlayground
//
//  Created by Fadhil Ikhsanta's Personal on 06/10/26.
//

import Foundation
@testable import SWRPlayground

final class MockProductAPIClient: ProductAPIClient {
    var fetchProductListCallCount: Int = 0
    var fetchProductDetailCallCount: Int = 0
    
    var fetchProductListResult: Result<ProductResponseDTO, Error>?
    var fetchProductDetailResult: Result<ProductDetailDTO, Error>?
    
    func fetchProductList(request: PageRequest) async throws -> ProductResponseDTO {
        fetchProductListCallCount += 1
        
        switch fetchProductListResult {
        case .success(let success):
            return success
        case .failure(let failure):
            throw failure
        case nil:
            throw MockLocalizedError(errorDescription: "No result.")
        }
    }
    
    func fetchProductDetail(id: Int) async throws -> ProductDetailDTO {
        fetchProductDetailCallCount += 1
        
        switch fetchProductDetailResult {
        case .success(let success):
            return success
        case .failure(let failure):
            throw failure
        case nil:
            throw MockLocalizedError(errorDescription: "No result.")
        }
    }
}
