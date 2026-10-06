//
//  ProductCacheTests.swift
//  SWRPlaygroundTests
//
//  Created by Fadhil Ikhsanta's Personal on 06/10/26.
//

import XCTest
@testable import SWRPlayground

final class ProductCacheTests: XCTestCase {
    private var sut: ProductCache!

    override func setUpWithError() throws {
        try super.setUpWithError()
        sut = ProductCache()
    }

    override func tearDownWithError() throws {
        sut = nil
        try super.tearDownWithError()
    }

    // MARK: ProductItemsByPage Cache Tests
    func testGetProductItemsByPage_whenNoItemCached_returnsNil() {
        // Given
        let request = makePageRequest(limit: 20, skip: 0)

        // When
        let cachedPage = sut.getProductItemsByPage(for: request)

        // Then
        XCTAssertNil(cachedPage)
    }

    func testGetProductItemsByPage_whenItemCached_returnsCachedProductItemsByPage() {
        // Given
        let request = makePageRequest(limit: 20, skip: 0)
        let page = makeProductItemsByPage(skip: 0, limit: 20)

        // When
        sut.insertProductItemsByPage(page, for: request)
        let cachedPage = sut.getProductItemsByPage(for: request)

        // Then
        XCTAssertEqual(cachedPage, page)
    }

    func testGetProductItemsByPage_whenRequestHasDifferentLimitOrSkip_returnsNilForNonMatchingRequest() {
        // Given
        let request1 = makePageRequest(limit: 20, skip: 0)
        let page1 = makeProductItemsByPage(
            products: [makeProductItem(id: 1, title: "Item 1")],
            skip: 0,
            limit: 20
        )

        let request2 = makePageRequest(limit: 20, skip: 20)
        let page2 = makeProductItemsByPage(
            products: [makeProductItem(id: 2, title: "Item 2")],
            skip: 20,
            limit: 20
        )

        let nonCachedRequest = makePageRequest(limit: 10, skip: 0)

        // When
        sut.insertProductItemsByPage(page1, for: request1)
        sut.insertProductItemsByPage(page2, for: request2)

        // Then
        XCTAssertEqual(sut.getProductItemsByPage(for: request1), page1)
        XCTAssertEqual(sut.getProductItemsByPage(for: request2), page2)
        XCTAssertNil(sut.getProductItemsByPage(for: nonCachedRequest))
    }

    func testInsertProductItemsByPage_whenOverwritingExistingPage_updatesCachedValue() {
        // Given
        let request = makePageRequest(limit: 20, skip: 0)
        let initialPage = makeProductItemsByPage(
            products: [makeProductItem(id: 1, title: "Initial")],
            total: 10
        )
        let updatedPage = makeProductItemsByPage(
            products: [makeProductItem(id: 1, title: "Updated")],
            total: 15
        )

        // When
        sut.insertProductItemsByPage(initialPage, for: request)
        XCTAssertEqual(sut.getProductItemsByPage(for: request), initialPage)

        sut.insertProductItemsByPage(updatedPage, for: request)

        // Then
        XCTAssertEqual(sut.getProductItemsByPage(for: request), updatedPage)
    }

    // MARK: ProductDetail Cache Tests
    func testGetProductDetail_whenNoProductCached_returnsNil() {
        // Given
        let productId = 1

        // When
        let cachedDetail = sut.getProductDetail(id: productId)

        // Then
        XCTAssertNil(cachedDetail)
    }

    func testGetProductDetail_whenProductCached_returnsCachedProductDetail() {
        // Given
        let detail = makeProductDetail(id: 1, title: "Mascara")

        // When
        sut.insertProductDetail(detail)
        let cachedDetail = sut.getProductDetail(id: detail.id)

        // Then
        XCTAssertEqual(cachedDetail, detail)
    }

    func testGetProductDetail_whenRequestingDifferentId_returnsNilForNonMatchingId() {
        // Given
        let detail1 = makeProductDetail(id: 1, title: "Product 1")
        let detail2 = makeProductDetail(id: 2, title: "Product 2")

        // When
        sut.insertProductDetail(detail1)
        sut.insertProductDetail(detail2)

        // Then
        XCTAssertEqual(sut.getProductDetail(id: 1), detail1)
        XCTAssertEqual(sut.getProductDetail(id: 2), detail2)
        XCTAssertNil(sut.getProductDetail(id: 999))
    }

    func testInsertProductDetail_whenOverwritingExistingDetail_updatesCachedValue() {
        // Given
        let initialDetail = makeProductDetail(id: 1, title: "Original Title", price: 10.0)
        let updatedDetail = makeProductDetail(id: 1, title: "Updated Title", price: 20.0)

        // When
        sut.insertProductDetail(initialDetail)
        XCTAssertEqual(sut.getProductDetail(id: 1), initialDetail)

        sut.insertProductDetail(updatedDetail)

        // Then
        XCTAssertEqual(sut.getProductDetail(id: 1), updatedDetail)
    }

    // MARK: Initialization & Configuration Tests
    func testInit_withCustomLimits_functionsCorrectly() {
        // Given
        let customCache = ProductCache(
            productItemsLimit: 5,
            productItemsTotalCostLimit: 1024,
            productDetailLimit: 10,
            productDetailTotalCostLimit: 2048
        )
        let request = makePageRequest(limit: 5, skip: 0)
        let page = makeProductItemsByPage(limit: 5)
        let detail = makeProductDetail(id: 42)

        // When
        customCache.insertProductItemsByPage(page, for: request)
        customCache.insertProductDetail(detail)

        // Then
        XCTAssertEqual(customCache.getProductItemsByPage(for: request), page)
        XCTAssertEqual(customCache.getProductDetail(id: 42), detail)
    }

    func testProductCache_conformsToProductCachingProtocol() {
        // Given
        let cachingService: ProductCaching = sut
        let request = makePageRequest(limit: 20, skip: 0)
        let page = makeProductItemsByPage()
        let detail = makeProductDetail(id: 5)

        // When
        cachingService.insertProductItemsByPage(page, for: request)
        cachingService.insertProductDetail(detail)

        // Then
        XCTAssertEqual(cachingService.getProductItemsByPage(for: request), page)
        XCTAssertEqual(cachingService.getProductDetail(id: 5), detail)
    }
}

// MARK: Helper Factory Methods
extension ProductCacheTests {
    private func makePageRequest(
        limit: Int = 20,
        skip: Int = 0
    ) -> PageRequest {
        PageRequest(limit: limit, skip: skip)
    }

    private func makeProductItem(
        id: Int = 1,
        title: String = "Test Product",
        category: String = "Test Category",
        price: Double = 9.99,
        thumbnailURL: URL? = URL(string: "https://example.com/image.jpg")
    ) -> ProductItem {
        ProductItem(
            id: id,
            title: title,
            category: category,
            price: price,
            thumbnailURL: thumbnailURL
        )
    }

    private func makeProductItemsByPage(
        products: [ProductItem]? = nil,
        total: Int = 100,
        skip: Int = 0,
        limit: Int = 20
    ) -> ProductItemsByPage {
        ProductItemsByPage(
            products: products ?? [makeProductItem()],
            total: total,
            skip: skip,
            limit: limit
        )
    }

    private func makeProductDetail(
        id: Int = 1,
        title: String = "Detail Product",
        category: String = "Detail Category",
        price: Double = 19.99,
        description: String = "Product description",
        imageURLs: [URL] = [URL(string: "https://example.com/image1.jpg")!]
    ) -> ProductDetail {
        ProductDetail(
            id: id,
            title: title,
            category: category,
            price: price,
            description: description,
            imageURLs: imageURLs
        )
    }
}
