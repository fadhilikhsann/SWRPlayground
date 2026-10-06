//
//  ProductPageCache.swift
//  SWRPlayground
//
//  Created by Fadhil Ikhsanta's Personal on 25/09/26.
//

import Foundation

protocol ProductCaching {
    func getProductItemsByPage(for request: PageRequest) -> ProductItemsByPage?
    func insertProductItemsByPage(_ page: ProductItemsByPage, for request: PageRequest)
	
	func getProductDetail(id: Int) -> ProductDetail?
	func insertProductDetail(_ product: ProductDetail)
}

final class ProductCache: ProductCaching {
    private let itemsByPageCache = NSCache<NSString, ProductItemsByPageCacheEntry>()
	private let detailCache = NSCache<NSString, ProductDetailCacheEntry>()

    init(
		productItemsLimit: Int = 20,
		productItemsTotalCostLimit: Int = 20 * 1024 * 1024,
		productDetailLimit: Int = 200,
		productDetailTotalCostLimit: Int = 20 * 1024 * 1024,
	) {
		itemsByPageCache.countLimit = productItemsLimit
		itemsByPageCache.totalCostLimit = productItemsTotalCostLimit
		detailCache.countLimit = productDetailLimit
		detailCache.totalCostLimit = productDetailTotalCostLimit
    }

    func getProductItemsByPage(for request: PageRequest) -> ProductItemsByPage? {
		itemsByPageCache.object(forKey: generateProductItemsCacheKey(for: request))?.page
    }

    func insertProductItemsByPage(_ page: ProductItemsByPage, for request: PageRequest) {
		itemsByPageCache.setObject(
			ProductItemsByPageCacheEntry(page: page),
			forKey: generateProductItemsCacheKey(for: request)
		)
    }
	
	func getProductDetail(id: Int) -> ProductDetail? {
		detailCache.object(forKey: generateProductDetailCacheKey(for: id))?.product
	}
	
	func insertProductDetail(_ product: ProductDetail) {
		detailCache.setObject(
			ProductDetailCacheEntry(product: product),
			forKey: generateProductDetailCacheKey(for: product.id)
		)
	}

    private func generateProductItemsCacheKey(for request: PageRequest) -> NSString {
        "products-limit:\(request.limit)-skip:\(request.skip)" as NSString
    }
	
	private func generateProductDetailCacheKey(for id: Int) -> NSString {
		"product-id:\(id)" as NSString
	}
}
