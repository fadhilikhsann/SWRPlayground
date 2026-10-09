//
//  MockProductCache.swift
//  SWRPlayground
//
//  Created by Fadhil Ikhsanta's Personal on 06/10/26.
//

@testable import SWRPlayground

actor MockProductCache: ProductCaching {
    var getProductItemsByPageCallCount: Int = 0
    var insertProductItemsByPageCallCount: Int = 0
    var getProductDetailCallCount: Int = 0
    var insertProductDetailCallCount: Int = 0
    
    private var productItemsByPage: [PageRequest: ProductItemsByPage] = [:]
    private var productDetails: [Int: ProductDetail] = [:]
    
    func getProductItemsByPage(for request: PageRequest) -> ProductItemsByPage? {
        getProductItemsByPageCallCount += 1
        return productItemsByPage[request]
    }
    
    func insertProductItemsByPage(_ page: ProductItemsByPage, for request: PageRequest) {
        insertProductItemsByPageCallCount += 1
        productItemsByPage[request] = page
    }
    
    func getProductDetail(id: Int) -> ProductDetail? {
        getProductDetailCallCount += 1
        return productDetails[id]
    }
    
    func insertProductDetail(_ product: ProductDetail) {
        insertProductDetailCallCount += 1
        productDetails[product.id] = product
    }
}
