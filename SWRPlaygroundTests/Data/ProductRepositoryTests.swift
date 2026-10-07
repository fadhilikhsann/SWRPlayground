//
//  ProductRepositoryTests.swift
//  SWRPlaygroundTests
//
//  Created by Fadhil Ikhsanta's Personal on 06/10/26.
//

import XCTest
@testable import SWRPlayground

final class ProductRepositoryTests: XCTestCase {
    private var sut: DefaultProductRepository!
    private var apiClient: MockProductAPIClient!
    private var cache: MockProductCache!

    override func setUpWithError() throws {
        try super.setUpWithError()
        apiClient = MockProductAPIClient()
        cache = MockProductCache()
        sut = DefaultProductRepository(apiClient: apiClient, cache: cache)
    }

    override func tearDownWithError() throws {
        sut = nil
        apiClient = nil
        cache = nil
        try super.tearDownWithError()
    }

    // MARK: - Protocol Conformance Tests
    func testConformsToProductRepository() {
        XCTAssertTrue((sut as Any) is ProductRepository)
    }

    // MARK: - observeProductItemsByPage Tests
    func testObserveProductItemsByPage_whenCacheIsEmptyAndNetworkSucceeds_emitsNetworkPageAndInsertsIntoCache() async throws {
        // Given
        let request = makePageRequest(limit: 20, skip: 0)
        let responseDTO = makeProductResponseDTO(skip: 0, limit: 20)
        let expectedPage = responseDTO.toDomain()
        apiClient.fetchProductListResult = .success(responseDTO)

        // When
        var emittedPages: [ProductItemsByPage] = []
        for try await page in sut.observeProductItemsByPage(for: request) {
            emittedPages.append(page)
        }

        // Then
        XCTAssertEqual(emittedPages.count, 1)
        XCTAssertEqual(emittedPages.first, expectedPage)
        XCTAssertEqual(cache.getProductItemsByPageCallCount, 1)
        XCTAssertEqual(apiClient.fetchProductListCallCount, 1)
        XCTAssertEqual(cache.insertProductItemsByPageCallCount, 1)
    }

    func testObserveProductItemsByPage_whenCacheHasDataAndNetworkSucceeds_emitsCachedThenNetworkPageAndUpdatesCache() async throws {
        // Given
        let request = makePageRequest(limit: 20, skip: 0)
        let cachedPage = makeProductItemsByPage(
            products: [makeProductItem(id: 1, title: "Cached Product")],
            skip: 0,
            limit: 20
        )
        cache.insertProductItemsByPage(cachedPage, for: request)

        let networkResponseDTO = makeProductResponseDTO(
            products: [makeProductItemDTO(id: 2, title: "Network Product")],
            skip: 0,
            limit: 20
        )
        let expectedNetworkPage = networkResponseDTO.toDomain()
        apiClient.fetchProductListResult = .success(networkResponseDTO)

        // When
        var emittedPages: [ProductItemsByPage] = []
        for try await page in sut.observeProductItemsByPage(for: request) {
            emittedPages.append(page)
        }

        // Then
        XCTAssertEqual(emittedPages.count, 2)
        XCTAssertEqual(emittedPages.first, cachedPage)
        XCTAssertEqual(emittedPages.last, expectedNetworkPage)
        XCTAssertEqual(cache.getProductItemsByPageCallCount, 1)
        XCTAssertEqual(apiClient.fetchProductListCallCount, 1)
        XCTAssertEqual(cache.insertProductItemsByPageCallCount, 2)
    }

    func testObserveProductItemsByPage_whenCachedDataEqualsNetworkData_emitsOnlyCachedPageAndUpdatesCache() async throws {
        // Given
        let request = makePageRequest(limit: 20, skip: 0)
        let productDTO = makeProductItemDTO(id: 1, title: "Same Product")
        let networkResponseDTO = makeProductResponseDTO(
            products: [productDTO],
            skip: 0,
            limit: 20
        )
        let expectedPage = networkResponseDTO.toDomain()
        cache.insertProductItemsByPage(expectedPage, for: request)
        apiClient.fetchProductListResult = .success(networkResponseDTO)

        // When
        var emittedPages: [ProductItemsByPage] = []
        for try await page in sut.observeProductItemsByPage(for: request) {
            emittedPages.append(page)
        }

        // Then
        XCTAssertEqual(emittedPages.count, 1)
        XCTAssertEqual(emittedPages.first, expectedPage)
        XCTAssertEqual(cache.getProductItemsByPageCallCount, 1)
        XCTAssertEqual(apiClient.fetchProductListCallCount, 1)
        XCTAssertEqual(cache.insertProductItemsByPageCallCount, 2)
    }

    func testObserveProductItemsByPage_whenCacheIsEmptyAndNetworkFails_throwsErrorAndDoesNotInsertIntoCache() async throws {
        // Given
        let request = makePageRequest(limit: 20, skip: 0)
        let expectedError = MockLocalizedError(errorDescription: "Network failure")
        apiClient.fetchProductListResult = .failure(expectedError)

        // When
        var emittedPages: [ProductItemsByPage] = []
        var caughtError: Error?
        do {
            for try await page in sut.observeProductItemsByPage(for: request) {
                emittedPages.append(page)
            }
        } catch {
            caughtError = error
        }

        // Then
        XCTAssertTrue(emittedPages.isEmpty)
        XCTAssertEqual((caughtError as? MockLocalizedError)?.errorDescription, expectedError.errorDescription)
        XCTAssertEqual(cache.getProductItemsByPageCallCount, 1)
        XCTAssertEqual(apiClient.fetchProductListCallCount, 1)
        XCTAssertEqual(cache.insertProductItemsByPageCallCount, 0)
    }

    func testObserveProductItemsByPage_whenCacheHasDataAndNetworkFails_emitsCachedPageThenThrowsError() async throws {
        // Given
        let request = makePageRequest(limit: 20, skip: 0)
        let cachedPage = makeProductItemsByPage(
            products: [makeProductItem(id: 1, title: "Cached Product")],
            skip: 0,
            limit: 20
        )
        cache.insertProductItemsByPage(cachedPage, for: request)

        let expectedError = MockLocalizedError(errorDescription: "Network failure after cache hit")
        apiClient.fetchProductListResult = .failure(expectedError)

        // When
        var emittedPages: [ProductItemsByPage] = []
        var caughtError: Error?
        do {
            for try await page in sut.observeProductItemsByPage(for: request) {
                emittedPages.append(page)
            }
        } catch {
            caughtError = error
        }

        // Then
        XCTAssertEqual(emittedPages.count, 1)
        XCTAssertEqual(emittedPages.first, cachedPage)
        XCTAssertEqual((caughtError as? MockLocalizedError)?.errorDescription, expectedError.errorDescription)
        XCTAssertEqual(cache.getProductItemsByPageCallCount, 1)
        XCTAssertEqual(apiClient.fetchProductListCallCount, 1)
        XCTAssertEqual(cache.insertProductItemsByPageCallCount, 1)
    }

    func testObserveProductItemsByPage_whenTaskIsCancelled_finishesWithoutThrowingError() async throws {
        // Given
        let request = makePageRequest(limit: 20, skip: 0)

        // When
        let task = Task {
            var pages: [ProductItemsByPage] = []
            for try await page in sut.observeProductItemsByPage(for: request) {
                pages.append(page)
            }
            return pages
        }

        task.cancel()
        let result = await task.result

        // Then
        switch result {
        case .success(let pages):
            XCTAssertTrue(pages.isEmpty)
        case .failure(let error):
            XCTAssertTrue(error is CancellationError)
        }
    }

    // MARK: - observeProductDetail Tests
    func testObserveProductDetail_whenCacheIsEmptyAndNetworkSucceeds_emitsNetworkDetailAndInsertsIntoCache() async throws {
        // Given
        let productId = 1
        let detailDTO = makeProductDetailDTO(id: productId)
        let expectedDetail = detailDTO.toDomain()
        apiClient.fetchProductDetailResult = .success(detailDTO)

        // When
        var emittedDetails: [ProductDetail] = []
        for try await detail in sut.observeProductDetail(id: productId) {
            emittedDetails.append(detail)
        }

        // Then
        XCTAssertEqual(emittedDetails.count, 1)
        XCTAssertEqual(emittedDetails.first, expectedDetail)
        XCTAssertEqual(cache.getProductDetailCallCount, 1)
        XCTAssertEqual(apiClient.fetchProductDetailCallCount, 1)
        XCTAssertEqual(cache.insertProductDetailCallCount, 1)
    }

    func testObserveProductDetail_whenCacheHasDataAndNetworkSucceeds_emitsCachedThenNetworkDetailAndUpdatesCache() async throws {
        // Given
        let productId = 1
        let cachedDetail = makeProductDetail(id: productId, title: "Cached Product Detail")
        cache.insertProductDetail(cachedDetail)

        let networkDetailDTO = makeProductDetailDTO(id: productId, title: "Network Product Detail")
        let expectedNetworkDetail = networkDetailDTO.toDomain()
        apiClient.fetchProductDetailResult = .success(networkDetailDTO)

        // When
        var emittedDetails: [ProductDetail] = []
        for try await detail in sut.observeProductDetail(id: productId) {
            emittedDetails.append(detail)
        }

        // Then
        XCTAssertEqual(emittedDetails.count, 2)
        XCTAssertEqual(emittedDetails.first, cachedDetail)
        XCTAssertEqual(emittedDetails.last, expectedNetworkDetail)
        XCTAssertEqual(cache.getProductDetailCallCount, 1)
        XCTAssertEqual(apiClient.fetchProductDetailCallCount, 1)
        XCTAssertEqual(cache.insertProductDetailCallCount, 2)
    }

    func testObserveProductDetail_whenCachedDataEqualsNetworkData_emitsOnlyCachedDetailAndUpdatesCache() async throws {
        // Given
        let productId = 1
        let detailDTO = makeProductDetailDTO(id: productId, title: "Same Detail Product")
        let expectedDetail = detailDTO.toDomain()
        cache.insertProductDetail(expectedDetail)
        apiClient.fetchProductDetailResult = .success(detailDTO)

        // When
        var emittedDetails: [ProductDetail] = []
        for try await detail in sut.observeProductDetail(id: productId) {
            emittedDetails.append(detail)
        }

        // Then
        XCTAssertEqual(emittedDetails.count, 1)
        XCTAssertEqual(emittedDetails.first, expectedDetail)
        XCTAssertEqual(cache.getProductDetailCallCount, 1)
        XCTAssertEqual(apiClient.fetchProductDetailCallCount, 1)
        XCTAssertEqual(cache.insertProductDetailCallCount, 2)
    }

    func testObserveProductDetail_whenCacheIsEmptyAndNetworkFails_throwsErrorAndDoesNotInsertIntoCache() async throws {
        // Given
        let productId = 1
        let expectedError = MockLocalizedError(errorDescription: "Detail network failure")
        apiClient.fetchProductDetailResult = .failure(expectedError)

        // When
        var emittedDetails: [ProductDetail] = []
        var caughtError: Error?
        do {
            for try await detail in sut.observeProductDetail(id: productId) {
                emittedDetails.append(detail)
            }
        } catch {
            caughtError = error
        }

        // Then
        XCTAssertTrue(emittedDetails.isEmpty)
        XCTAssertEqual((caughtError as? MockLocalizedError)?.errorDescription, expectedError.errorDescription)
        XCTAssertEqual(cache.getProductDetailCallCount, 1)
        XCTAssertEqual(apiClient.fetchProductDetailCallCount, 1)
        XCTAssertEqual(cache.insertProductDetailCallCount, 0)
    }

    func testObserveProductDetail_whenCacheHasDataAndNetworkFails_emitsCachedDetailThenThrowsError() async throws {
        // Given
        let productId = 1
        let cachedDetail = makeProductDetail(id: productId, title: "Cached Detail")
        cache.insertProductDetail(cachedDetail)

        let expectedError = MockLocalizedError(errorDescription: "Detail network failure after cache hit")
        apiClient.fetchProductDetailResult = .failure(expectedError)

        // When
        var emittedDetails: [ProductDetail] = []
        var caughtError: Error?
        do {
            for try await detail in sut.observeProductDetail(id: productId) {
                emittedDetails.append(detail)
            }
        } catch {
            caughtError = error
        }

        // Then
        XCTAssertEqual(emittedDetails.count, 1)
        XCTAssertEqual(emittedDetails.first, cachedDetail)
        XCTAssertEqual((caughtError as? MockLocalizedError)?.errorDescription, expectedError.errorDescription)
        XCTAssertEqual(cache.getProductDetailCallCount, 1)
        XCTAssertEqual(apiClient.fetchProductDetailCallCount, 1)
        XCTAssertEqual(cache.insertProductDetailCallCount, 1)
    }

    func testObserveProductDetail_whenTaskIsCancelled_finishesWithoutThrowingError() async throws {
        // Given
        let productId = 1

        // When
        let task = Task {
            var details: [ProductDetail] = []
            for try await detail in sut.observeProductDetail(id: productId) {
                details.append(detail)
            }
            return details
        }

        task.cancel()
        let result = await task.result

        // Then
        switch result {
        case .success(let details):
            XCTAssertTrue(details.isEmpty)
        case .failure(let error):
            XCTAssertTrue(error is CancellationError)
        }
    }
}

// MARK: - Helper Methods
extension ProductRepositoryTests {
    private func makePageRequest(
        limit: Int = 20,
        skip: Int = 0
    ) -> PageRequest {
        PageRequest(limit: limit, skip: skip)
    }

    private func makeProductItemDTO(
        id: Int = 1,
        title: String = "Test Product",
        category: String = "Test Category",
        price: Double = 9.99,
        thumbnail: String = "https://example.com/thumbnail.jpg"
    ) -> ProductItemDTO {
        ProductItemDTO(
            id: id,
            title: title,
            category: category,
            price: price,
            thumbnail: thumbnail
        )
    }

    private func makeProductResponseDTO(
        products: [ProductItemDTO]? = nil,
        total: Int = 100,
        skip: Int = 0,
        limit: Int = 20
    ) -> ProductResponseDTO {
        ProductResponseDTO(
            products: products ?? [makeProductItemDTO()],
            total: total,
            skip: skip,
            limit: limit
        )
    }

    private func makeProductDetailDTO(
        id: Int = 1,
        title: String = "Detail Product",
        category: String = "Detail Category",
        price: Double = 19.99,
        description: String = "Product description",
        images: [String] = ["https://example.com/image1.jpg"]
    ) -> ProductDetailDTO {
        ProductDetailDTO(
            id: id,
            title: title,
            category: category,
            price: price,
            description: description,
            images: images
        )
    }

    private func makeProductItem(
        id: Int = 1,
        title: String = "Test Product",
        category: String = "Test Category",
        price: Double = 9.99,
        thumbnailURL: URL? = URL(string: "https://example.com/thumbnail.jpg")
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
