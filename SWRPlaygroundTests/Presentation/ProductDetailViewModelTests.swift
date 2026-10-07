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

    // MARK: - Protocol Conformance Tests
    func testConformsToProductDetailViewModelProtocol() {
        XCTAssertTrue((sut as Any) is ProductDetailViewModelProtocol)
    }

    // MARK: - Initial State Tests
    func testInit_initialStateAndPropertiesAreCorrect() {
        var recordedStates: [TableViewState<ProductDetailTask, [ProductDetailRow]>] = []
        sut.statePublisher
            .sink { recordedStates.append($0) }
            .store(in: &cancellables)

        XCTAssertEqual(recordedStates, [.start])
        XCTAssertTrue(sut.imageURLs.isEmpty)
        XCTAssertNil(sut.title)
        XCTAssertNil(sut.category)
        XCTAssertNil(sut.price)
        XCTAssertNil(sut.description)
    }

    // MARK: - Refresh Tests
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
        XCTAssertEqual(sut.imageURLs, networkDetail.imageURLs)
        XCTAssertEqual(sut.title, networkDetail.title)
        XCTAssertEqual(sut.category, networkDetail.category)
        XCTAssertEqual(sut.price, networkDetail.price)
        XCTAssertEqual(sut.description, networkDetail.description)
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
        XCTAssertEqual(sut.title, detail.title)
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

        let error = MockLocalizedError(errorDescription: "Failed to fetch product detail")
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
        XCTAssertTrue(sut.imageURLs.isEmpty)
        XCTAssertNil(sut.title)
        XCTAssertNil(sut.category)
        XCTAssertNil(sut.price)
        XCTAssertNil(sut.description)
        XCTAssertEqual(recordedStates, [
            .start,
            .runningTask(.refresh),
            .errorMessage("Failed to fetch product detail."),
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
        XCTAssertEqual(sut.title, cachedDetail.title)
        XCTAssertEqual(sut.category, cachedDetail.category)
        XCTAssertEqual(sut.price, cachedDetail.price)
        XCTAssertEqual(sut.description, cachedDetail.description)
        XCTAssertEqual(sut.imageURLs, cachedDetail.imageURLs)
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

// MARK: - Helper Methods
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
