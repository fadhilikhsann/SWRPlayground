//
//  ProductDetailViewModelTests.swift
//  SWRPlaygroundTests
//
//  Created by Fadhil Ikhsanta's Personal on 07/10/26.
//

import Combine
import XCTest
@testable import SWRPlayground

@MainActor
final class ProductDetailViewModelTests: XCTestCase {
    private var coordinator: MockAppCoordinator!
    private var repository: MockProductRepository!
    private var productId: Int!
    private var sut: ProductDetailViewModel!
    private var cancellables: Set<AnyCancellable>!

    override func setUpWithError() throws {
        try super.setUpWithError()
        coordinator = MockAppCoordinator()
        repository = MockProductRepository()
        productId = 1
        sut = ProductDetailViewModel(id: productId, repository: repository)
        sut.coordinator = coordinator
        cancellables = []
    }

    override func tearDownWithError() throws {
        cancellables = nil
        sut = nil
        productId = nil
        repository = nil
        coordinator = nil
        try super.tearDownWithError()
    }

    // MARK: - Protocol conformance tests
    func testConformsToProductDetailViewModelProtocol() {
        XCTAssertTrue((sut as Any) is ProductDetailViewModelProtocol)
    }

    // MARK: - Initial state tests
    func testInit_initialStateAndPropertiesAreCorrect() {
        var recordedStates: [TableViewState<ProductDetailTask, [ProductDetailRow]>] = []
        sut.statePublisher
            .sink { recordedStates.append($0) }
            .store(in: &cancellables)

        XCTAssertEqual(recordedStates, [.start])
        XCTAssertTrue(sut.getImageURLs().isEmpty)
        XCTAssertNil(sut.getTitle())
        XCTAssertNil(sut.getCategory())
        XCTAssertNil(sut.getPrice())
        XCTAssertNil(sut.getDescription())
    }

    // MARK: - Refresh tests
    func testRefresh_whenRepositoryEmitsCachedAndDifferentNetworkData_updatesPropertiesAndEmitsResultStates() async {
        let expectation = expectation(description: "Refresh finished with SWR cached and network emissions.")
        var recordedStates: [TableViewState<ProductDetailTask, [ProductDetailRow]>] = []

        let cachedDetail = makeProductDetail(id: productId, title: "Cached Product", price: 10.0)
        let networkDetail = makeProductDetail(id: productId, title: "Updated Product", price: 15.0)

        repository.observeProductDetailStreamClosure = {
            AsyncThrowingStream { continuation in
                continuation.yield(cachedDetail)
                continuation.yield(networkDetail)
                continuation.finish()
            }
        }

        sut.statePublisher
            .sink { state in
                recordedStates.append(state)
                if state == .endTask {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        sut.refresh()

        await fulfillment(of: [expectation], timeout: 2.0)

        XCTAssertEqual(repository.observeProductDetailCallCount, 1)
        XCTAssertEqual(sut.getImageURLs(), networkDetail.imageURLs)
        XCTAssertEqual(sut.getTitle(), networkDetail.title)
        XCTAssertEqual(sut.getCategory(), networkDetail.category)
        XCTAssertEqual(sut.getPrice(), networkDetail.price)
        XCTAssertEqual(sut.getDescription(), networkDetail.description)
        XCTAssertEqual(recordedStates, [
            .start,
            .runningTask(.refresh),
            .resultTask([.image, .detail], task: .refresh),
            .resultTask([.image, .detail], task: .refresh),
            .endTask
        ])
    }

    func testRefresh_whenRepositoryEmitsCachedAndEqualNetworkData_emitsResultStateOnlyOnce() async {
        let expectation = expectation(description: "Refresh finished.")
        var recordedStates: [TableViewState<ProductDetailTask, [ProductDetailRow]>] = []

        let detail = makeProductDetail(id: productId, title: "Same Product")

        repository.observeProductDetailStreamClosure = {
            AsyncThrowingStream { continuation in
                continuation.yield(detail)
                continuation.yield(detail)
                continuation.finish()
            }
        }

        sut.statePublisher
            .sink { state in
                recordedStates.append(state)
                if state == .endTask {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        sut.refresh()

        await fulfillment(of: [expectation], timeout: 2.0)

        XCTAssertEqual(repository.observeProductDetailCallCount, 1)
        XCTAssertEqual(sut.getTitle(), detail.title)
        XCTAssertEqual(recordedStates, [
            .start,
            .runningTask(.refresh),
            .resultTask([.image, .detail], task: .refresh),
            .endTask
        ])
    }

    func testRefresh_whenRepositoryThrowsErrorWithoutEmissions_emitsEndTaskWithoutUpdatingProperties() async {
        let expectation = expectation(description: "Refresh finished with error.")
        var recordedStates: [TableViewState<ProductDetailTask, [ProductDetailRow]>] = []
        let errorDescription = "Failed to fetch product detail."
        let error = MockLocalizedError(errorDescription: errorDescription)
        repository.observeProductDetailStreamClosure = {
            AsyncThrowingStream { continuation in
                continuation.finish(throwing: error)
            }
        }

        sut.statePublisher
            .sink { state in
                recordedStates.append(state)
                if state == .endTask {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        sut.refresh()

        await fulfillment(of: [expectation], timeout: 2.0)

        XCTAssertEqual(repository.observeProductDetailCallCount, 1)
        XCTAssertTrue(sut.getImageURLs().isEmpty)
        XCTAssertNil(sut.getTitle())
        XCTAssertNil(sut.getCategory())
        XCTAssertNil(sut.getPrice())
        XCTAssertNil(sut.getDescription())
        XCTAssertEqual(recordedStates, [
            .start,
            .runningTask(.refresh),
            .errorMessage(errorDescription),
            .endTask
        ])
    }

    func testRefresh_whenRepositoryThrowsErrorAfterEmittingCachedData_retainsCachedData() async {
        let expectation = expectation(description: "Refresh finished after cached hit and network error.")
        var recordedStates: [TableViewState<ProductDetailTask, [ProductDetailRow]>] = []

        let cachedDetail = makeProductDetail(id: productId, title: "Cached Product")
        let error = MockLocalizedError(errorDescription: "Network error after cache.")

        repository.observeProductDetailStreamClosure = {
            AsyncThrowingStream { continuation in
                continuation.yield(cachedDetail)
                continuation.finish(throwing: error)
            }
        }

        sut.statePublisher
            .sink { state in
                recordedStates.append(state)
                if state == .endTask {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        sut.refresh()

        await fulfillment(of: [expectation], timeout: 2.0)

        XCTAssertEqual(repository.observeProductDetailCallCount, 1)
        XCTAssertEqual(sut.getTitle(), cachedDetail.title)
        XCTAssertEqual(sut.getCategory(), cachedDetail.category)
        XCTAssertEqual(sut.getPrice(), cachedDetail.price)
        XCTAssertEqual(sut.getDescription(), cachedDetail.description)
        XCTAssertEqual(sut.getImageURLs(), cachedDetail.imageURLs)
        XCTAssertEqual(recordedStates, [
            .start,
            .runningTask(.refresh),
            .resultTask([.image, .detail], task: .refresh),
            .endTask
        ])
    }

    func testRefresh_whenTaskIsCancelled_endsTaskWithoutUpdatingProperties() async {
        let expectation = expectation(description: "Refresh finished after cancellation error.")
        var recordedStates: [TableViewState<ProductDetailTask, [ProductDetailRow]>] = []

        repository.observeProductDetailStreamClosure = {
            AsyncThrowingStream { continuation in
                continuation.finish(throwing: CancellationError())
            }
        }
        
        sut.statePublisher
            .sink { state in
                recordedStates.append(state)
                if state == .endTask {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        sut.refresh()

        await fulfillment(of: [expectation], timeout: 2.0)

        XCTAssertEqual(repository.observeProductDetailCallCount, 1)
        XCTAssertEqual(recordedStates, [
            .start,
            .runningTask(.refresh),
            .endTask
        ])
    }
}

// MARK: - Support methods
extension ProductDetailViewModelTests {
    private func makeProductDetail(
        id: Int = 1,
        title: String = "Test Product",
        category: String = "Test Category",
        price: Double = 29.99,
        description: String = "Test Description",
        imageURLs: [URL] = [URL(string: "https://example.com/image.jpg")!]
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
