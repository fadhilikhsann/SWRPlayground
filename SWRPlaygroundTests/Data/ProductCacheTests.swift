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
    
    // MARK: - Protocol conformance tests
    func testConformsToProductCaching() {
        XCTAssertTrue((sut as Any) is ProductCaching)
    }

    // MARK: - ProductItemsByPage cache tests
    func testGetProductItemsByPage_whenNoItemCached_returnsNil() async {
        // Given
        let request = makePageRequest(limit: 20, skip: 0)

        // When
        let cachedPage = await sut.getProductItemsByPage(for: request)

        // Then
        XCTAssertNil(cachedPage)
    }

    func testGetProductItemsByPage_whenItemCached_returnsCachedProductItemsByPage() async {
        // Given
        let request = makePageRequest(limit: 20, skip: 0)
        let page = makeProductItemsByPage(skip: 0, limit: 20)

        // When
        await sut.insertProductItemsByPage(page, for: request)
        let cachedPage = await sut.getProductItemsByPage(for: request)

        // Then
        XCTAssertEqual(cachedPage, page)
    }

    func testGetProductItemsByPage_whenRequestHasDifferentLimitOrSkip_returnsNilForNonMatchingRequest() async {
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
        await sut.insertProductItemsByPage(page1, for: request1)
        await sut.insertProductItemsByPage(page2, for: request2)

        // Then
        let getProductItemsByPageForRequest1 = await sut.getProductItemsByPage(for: request1)
        let getProductItemsByPageForRequest2 = await sut.getProductItemsByPage(for: request2)
        let getProductItemsByPageForNonCachedRequest = await sut.getProductItemsByPage(for: nonCachedRequest)
        
        XCTAssertEqual(getProductItemsByPageForRequest1, page1)
        XCTAssertEqual(getProductItemsByPageForRequest2, page2)
        XCTAssertNil(getProductItemsByPageForNonCachedRequest)
    }

    func testInsertProductItemsByPage_whenOverwritingExistingPage_updatesCachedValue() async {
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
        await sut.insertProductItemsByPage(initialPage, for: request)
        var cachedPage = await sut.getProductItemsByPage(for: request)
        XCTAssertEqual(cachedPage, initialPage)

        await sut.insertProductItemsByPage(updatedPage, for: request)

        // Then
        cachedPage = await sut.getProductItemsByPage(for: request)
        XCTAssertEqual(cachedPage, updatedPage)
    }

    // MARK: - ProductDetail cache tests
    func testGetProductDetail_whenNoProductCached_returnsNil() async {
        // Given
        let productId = 1

        // When
        let cachedDetail = await sut.getProductDetail(id: productId)

        // Then
        XCTAssertNil(cachedDetail)
    }

    func testGetProductDetail_whenProductCached_returnsCachedProductDetail() async {
        // Given
        let detail = makeProductDetail(id: 1, title: "Mascara")

        // When
        await sut.insertProductDetail(detail)

        // Then
        let cachedDetail = await sut.getProductDetail(id: detail.id)
        XCTAssertEqual(cachedDetail, detail)
    }

    func testGetProductDetail_whenRequestingDifferentId_returnsNilForNonMatchingId() async {
        // Given
        let detail1 = makeProductDetail(id: 1, title: "Product 1")
        let detail2 = makeProductDetail(id: 2, title: "Product 2")

        // When
        await sut.insertProductDetail(detail1)
        await sut.insertProductDetail(detail2)

        // Then
        let getProductDetailForId1 = await sut.getProductDetail(id: 1)
        let getProductDetailForId2 = await sut.getProductDetail(id: 2)
        let getProductDetailForNonExistingId = await sut.getProductDetail(id: 999)
        
        XCTAssertEqual(getProductDetailForId1, detail1)
        XCTAssertEqual(getProductDetailForId2, detail2)
        XCTAssertNil(getProductDetailForNonExistingId)
    }

    func testInsertProductDetail_whenOverwritingExistingDetail_updatesCachedValue() async {
        // Given
        let initialDetail = makeProductDetail(id: 1, title: "Original Title", price: 10.0)
        let updatedDetail = makeProductDetail(id: 1, title: "Updated Title", price: 20.0)

        // When
        await sut.insertProductDetail(initialDetail)
        var cachedData = await sut.getProductDetail(id: 1)
        XCTAssertEqual(cachedData, initialDetail)

        await sut.insertProductDetail(updatedDetail)

        // Then
        cachedData = await sut.getProductDetail(id: 1)
        XCTAssertEqual(cachedData, updatedDetail)
    }

    // MARK: - Initialization tests
    func testInit_withCustomLimits_functionsCorrectly() async {
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
        await customCache.insertProductItemsByPage(page, for: request)
        await customCache.insertProductDetail(detail)

        // Then
        let getProductItems = await customCache.getProductItemsByPage(for: request)
        let getProductDetail = await customCache.getProductDetail(id: 42)
        
        XCTAssertEqual(getProductItems, page)
        XCTAssertEqual(getProductDetail, detail)
    }
}

// MARK: - Support methods
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
