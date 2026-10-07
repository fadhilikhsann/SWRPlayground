//
//  ProductListViewModelTests.swift
//  SWRPlaygroundTests
//
//  Created by Fadhil Ikhsanta's Personal on 07/10/26.
//

import Combine
import XCTest
@testable import SWRPlayground

@MainActor
final class ProductListViewModelTests: XCTestCase {
    private var coordinator: MockAppCoordinator!
    private var repository: MockProductRepository!
    private var sut: ProductListViewModel!
    private var cancellables: Set<AnyCancellable>!

    override func setUpWithError() throws {
        try super.setUpWithError()
        coordinator = MockAppCoordinator()
        repository = MockProductRepository()
        sut = ProductListViewModel(repository: repository)
        sut.coordinator = coordinator
        cancellables = []
    }

    override func tearDownWithError() throws {
        cancellables = nil
        sut = nil
        repository = nil
        coordinator = nil
        try super.tearDownWithError()
    }

    // MARK: - Protocol Conformance Tests
    func testConformsToProductListViewModelProtocol() {
        XCTAssertTrue((sut as Any) is ProductListViewModelProtocol)
    }

    // MARK: - Initial State Tests
    func testInit_initialStateAndPropertiesAreCorrect() {
        var recordedStates: [TableViewState<ProductListTask, ProductListConfig>] = []
        sut.statePublisher
            .sink { recordedStates.append($0) }
            .store(in: &cancellables)

        XCTAssertEqual(recordedStates, [.start])
        XCTAssertEqual(sut.getTotalProductsCount(), 0)
        XCTAssertNil(sut.getProductItem(id: 1))
    }

    // MARK: - start Tests
    func testStart_whenStateIsStart_triggersRefreshTaskAndHandlesSWRStream() async {
        let expectation = expectation(description: "State transitions to endTask.")
        var recordedStates: [TableViewState<ProductListTask, ProductListConfig>] = []

        let cachedItem = makeProductItem(id: 1, title: "Cached Product")
        let cachedPage = makeProductItemsByPage(products: [cachedItem], total: 10)

        let networkItem1 = makeProductItem(id: 1, title: "Revalidated Product 1")
        let networkItem2 = makeProductItem(id: 2, title: "Revalidated Product 2")
        let networkPage = makeProductItemsByPage(products: [networkItem1, networkItem2], total: 10)

        repository.observeProductItemsByPageResult = AsyncThrowingStream { continuation in
            continuation.yield(cachedPage)
            continuation.yield(networkPage)
            continuation.finish()
        }

        sut.statePublisher
            .sink { state in
                recordedStates.append(state)
                if state == .endTask {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        sut.start()

        await fulfillment(of: [expectation], timeout: 2.0)

        XCTAssertEqual(repository.observeProductItemsByPageCallCount, 1)
        XCTAssertEqual(sut.getTotalProductsCount(), 10)
        XCTAssertEqual(sut.getProductItem(id: 1), networkItem1)
        XCTAssertEqual(sut.getProductItem(id: 2), networkItem2)
        XCTAssertEqual(recordedStates, [
            .start,
            .runningTask(.refresh),
            .resultTask(ProductListConfig(ids: [1], reconfigIds: [1]), task: .refresh),
            .resultTask(ProductListConfig(ids: [1, 2], reconfigIds: [1]), task: .refresh),
            .endTask
        ])
    }

    func testStart_whenStateIsNotStart_doesNotTriggerRefreshTask() async {
        let expectation = expectation(description: "First refresh finished.")
        let page = makeProductItemsByPage(products: [makeProductItem(id: 1)], total: 10)
        repository.observeProductItemsByPageResult = AsyncThrowingStream { continuation in
            continuation.yield(page)
            continuation.finish()
        }

        sut.statePublisher
            .sink { state in
                if state == .endTask {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        sut.start()
        await fulfillment(of: [expectation], timeout: 2.0)

        XCTAssertEqual(repository.observeProductItemsByPageCallCount, 1)

        sut.start()

        try? await Task.sleep(nanoseconds: 50_000_000)

        XCTAssertEqual(repository.observeProductItemsByPageCallCount, 1)
    }

    // MARK: - Refresh Tests
    func testRequest_refresh_whenPageSizeIsZeroOrNegative_emitsEndTaskWithoutObservingRepository() async {
        sut = ProductListViewModel(pageSize: 0, repository: repository)

        let expectation = expectation(description: "State transitions to endTask.")
        var recordedStates: [TableViewState<ProductListTask, ProductListConfig>] = []

        sut.statePublisher
            .sink { state in
                recordedStates.append(state)
                if state == .endTask {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        sut.request(.refresh)

        await fulfillment(of: [expectation], timeout: 2.0)

        XCTAssertEqual(repository.observeProductItemsByPageCallCount, 0)
        XCTAssertEqual(recordedStates, [.start, .endTask])
    }

    func testRequest_refresh_whenRepositoryEmitsCachedAndDifferentNetworkData_resetsWithCachedThenMergesNetworkData() async {
        let expectation = expectation(description: "Refresh finished with SWR cached and network emissions.")
        var recordedStates: [TableViewState<ProductListTask, ProductListConfig>] = []

        let cachedItem1 = makeProductItem(id: 1, title: "Cached Product 1")
        let cachedPage = makeProductItemsByPage(products: [cachedItem1], total: 10)

        let networkItem1 = makeProductItem(id: 1, title: "Updated Product 1")
        let networkItem2 = makeProductItem(id: 2, title: "New Product 2")
        let networkPage = makeProductItemsByPage(products: [networkItem1, networkItem2], total: 10)

        repository.observeProductItemsByPageResult = AsyncThrowingStream { continuation in
            continuation.yield(cachedPage)
            continuation.yield(networkPage)
            continuation.finish()
        }

        sut.statePublisher
            .sink { state in
                recordedStates.append(state)
                if state == .endTask {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        sut.request(.refresh)

        await fulfillment(of: [expectation], timeout: 2.0)

        XCTAssertEqual(recordedStates, [
            .start,
            .runningTask(.refresh),
            .resultTask(ProductListConfig(ids: [1], reconfigIds: [1]), task: .refresh),
            .resultTask(ProductListConfig(ids: [1, 2], reconfigIds: [1]), task: .refresh),
            .endTask
        ])
        XCTAssertEqual(sut.getProductItem(id: 1), networkItem1)
        XCTAssertEqual(sut.getProductItem(id: 2), networkItem2)
        XCTAssertEqual(sut.getTotalProductsCount(), 10)
    }

    func testRequest_refresh_whenRepositoryEmitsCachedAndEqualNetworkData_resetsWithCachedAndDoesNotEmitDuplicateResultState() async {
        let expectation = expectation(description: "Refresh finished.")
        var recordedStates: [TableViewState<ProductListTask, ProductListConfig>] = []

        let product = makeProductItem(id: 1, title: "Same Product")
        let cachedPage = makeProductItemsByPage(products: [product], total: 10)
        let networkPage = makeProductItemsByPage(products: [product], total: 10)

        repository.observeProductItemsByPageResult = AsyncThrowingStream { continuation in
            continuation.yield(cachedPage)
            continuation.yield(networkPage)
            continuation.finish()
        }

        sut.statePublisher
            .sink { state in
                recordedStates.append(state)
                if state == .endTask {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        sut.request(.refresh)

        await fulfillment(of: [expectation], timeout: 2.0)

        XCTAssertEqual(recordedStates, [
            .start,
            .runningTask(.refresh),
            .resultTask(ProductListConfig(ids: [1], reconfigIds: [1]), task: .refresh),
            .endTask
        ])
        XCTAssertEqual(sut.getProductItem(id: 1), product)
    }

    func testRequest_refresh_whenRepositoryThrowsErrorAndProductsIsEmpty_emitsErrorMessage() async {
        let expectation = expectation(description: "Refresh finished with error.")
        var recordedStates: [TableViewState<ProductListTask, ProductListConfig>] = []
        let errorDescription = "Failed to fetch products."
        let error = MockLocalizedError(errorDescription: errorDescription)
        repository.observeProductItemsByPageResult = AsyncThrowingStream { continuation in
            continuation.finish(throwing: error)
        }

        sut.statePublisher
            .sink { state in
                recordedStates.append(state)
                if state == .endTask {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        sut.request(.refresh)

        await fulfillment(of: [expectation], timeout: 2.0)

        XCTAssertEqual(recordedStates, [
            .start,
            .runningTask(.refresh),
            .errorMessage(errorDescription),
            .endTask
        ])
    }

    func testRequest_refresh_whenRepositoryThrowsErrorAfterEmittingCachedData_retainsCachedDataWithoutEmittingErrorMessage() async {
        let expectation = expectation(description: "Refresh finished after SWR cached hit and network error.")
        var recordedStates: [TableViewState<ProductListTask, ProductListConfig>] = []

        let cachedItem = makeProductItem(id: 1, title: "Cached Product")
        let cachedPage = makeProductItemsByPage(products: [cachedItem], total: 10)
        let networkError = MockLocalizedError(errorDescription: "Network failure after cache.")

        repository.observeProductItemsByPageResult = AsyncThrowingStream { continuation in
            continuation.yield(cachedPage)
            continuation.finish(throwing: networkError)
        }

        sut.statePublisher
            .sink { state in
                recordedStates.append(state)
                if state == .endTask {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        sut.request(.refresh)

        await fulfillment(of: [expectation], timeout: 2.0)

        XCTAssertEqual(recordedStates, [
            .start,
            .runningTask(.refresh),
            .resultTask(ProductListConfig(ids: [1], reconfigIds: [1]), task: .refresh),
            .endTask
        ])
        XCTAssertEqual(sut.getProductItem(id: 1), cachedItem)
    }

    func testRequest_refresh_whenTaskIsCancelled_endsTaskWithoutErrorMessage() async {
        let expectation = expectation(description: "Refresh finished after cancellation error.")
        var recordedStates: [TableViewState<ProductListTask, ProductListConfig>] = []

        repository.observeProductItemsByPageResult = AsyncThrowingStream { continuation in
            continuation.finish(throwing: CancellationError())
        }

        sut.statePublisher
            .sink { state in
                recordedStates.append(state)
                if state == .endTask {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        sut.request(.refresh)

        await fulfillment(of: [expectation], timeout: 2.0)

        XCTAssertEqual(recordedStates, [
            .start,
            .runningTask(.refresh),
            .endTask
        ])
    }

    // MARK: - Load More Tests
    func testRequest_loadMore_whenStateIsRunningTask_doesNotExecuteLoadMore() async {
        let (stream, continuation) = AsyncThrowingStream<ProductItemsByPage, Error>.makeStream()
        repository.observeProductItemsByPageResult = stream

        let expectation = expectation(description: "State enters runningTask.")
        sut.statePublisher
            .sink { state in
                if state == .runningTask(.refresh) {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        sut.request(.refresh)
        await fulfillment(of: [expectation], timeout: 2.0)

        try? await Task.sleep(nanoseconds: 20_000_000)

        XCTAssertEqual(repository.observeProductItemsByPageCallCount, 1)

        sut.request(.loadMore)

        XCTAssertEqual(repository.observeProductItemsByPageCallCount, 1)

        continuation.finish()
    }

    func testRequest_loadMore_whenStateIsResultTaskWithRefresh_doesNotExecuteLoadMore() async {
        let expectation = expectation(description: "First emission occurs.")

        let page = makeProductItemsByPage(products: [makeProductItem(id: 1)], total: 10)
        let (stream, continuation) = AsyncThrowingStream<ProductItemsByPage, Error>.makeStream()
        repository.observeProductItemsByPageResult = stream

        sut.statePublisher
            .sink { state in
                if case .resultTask = state {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        sut.request(.refresh)
        continuation.yield(page)

        await fulfillment(of: [expectation], timeout: 2.0)

        sut.request(.loadMore)

        XCTAssertEqual(repository.observeProductItemsByPageCallCount, 1)

        continuation.finish()
    }

    func testRequest_loadMore_whenProductsIsEmpty_doesNotExecuteLoadMore() async {
        let expectation = expectation(description: "Refresh with empty list finished.")

        let emptyPage = makeProductItemsByPage(products: [], total: 0)
        repository.observeProductItemsByPageResult = AsyncThrowingStream { continuation in
            continuation.yield(emptyPage)
            continuation.finish()
        }

        sut.statePublisher
            .sink { state in
                if state == .endTask {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        sut.request(.refresh)
        await fulfillment(of: [expectation], timeout: 2.0)

        XCTAssertEqual(repository.observeProductItemsByPageCallCount, 1)

        sut.request(.loadMore)
        try? await Task.sleep(nanoseconds: 50_000_000)

        XCTAssertEqual(repository.observeProductItemsByPageCallCount, 1)
    }

    func testRequest_loadMore_whenProductsCountEqualsTotalProductsCount_doesNotExecuteLoadMore() async {
        let expectation = expectation(description: "Refresh finished.")

        let item1 = makeProductItem(id: 1)
        let item2 = makeProductItem(id: 2)
        let page = makeProductItemsByPage(products: [item1, item2], total: 2)

        repository.observeProductItemsByPageResult = AsyncThrowingStream { continuation in
            continuation.yield(page)
            continuation.finish()
        }

        sut.statePublisher
            .sink { state in
                if state == .endTask {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        sut.request(.refresh)
        await fulfillment(of: [expectation], timeout: 2.0)

        XCTAssertEqual(repository.observeProductItemsByPageCallCount, 1)

        sut.request(.loadMore)
        try? await Task.sleep(nanoseconds: 50_000_000)

        XCTAssertEqual(repository.observeProductItemsByPageCallCount, 1)
    }

    func testRequest_loadMore_whenRepositoryEmitsCachedAndNetworkData_mergesCachedThenMergesNetworkData() async {
        let refreshExpectation = expectation(description: "Refresh finished.")
        let loadMoreExpectation = expectation(description: "Load more finished.")

        var recordedStates: [TableViewState<ProductListTask, ProductListConfig>] = []

        let item1 = makeProductItem(id: 1, title: "Product 1")
        let refreshCachedPage = makeProductItemsByPage(products: [item1], total: 10)

        repository.observeProductItemsByPageResult = AsyncThrowingStream { continuation in
            continuation.yield(refreshCachedPage)
            continuation.finish()
        }

        sut.statePublisher
            .sink { state in
                recordedStates.append(state)
                if state == .endTask {
                    if recordedStates.contains(.runningTask(.loadMore)) {
                        loadMoreExpectation.fulfill()
                    } else if recordedStates.contains(.runningTask(.refresh)) {
                        refreshExpectation.fulfill()
                    }
                }
            }
            .store(in: &cancellables)

        sut.request(.refresh)
        await fulfillment(of: [refreshExpectation], timeout: 2.0)

        let loadMoreCachedItem = makeProductItem(id: 2, title: "Product 2 Cached")
        let loadMoreCachedPage = makeProductItemsByPage(products: [loadMoreCachedItem], total: 10)

        let loadMoreNetworkItem = makeProductItem(id: 2, title: "Product 2 Network")
        let loadMoreNetworkPage = makeProductItemsByPage(products: [loadMoreNetworkItem], total: 10)

        repository.observeProductItemsByPageResult = AsyncThrowingStream { continuation in
            continuation.yield(loadMoreCachedPage)
            continuation.yield(loadMoreNetworkPage)
            continuation.finish()
        }

        sut.request(.loadMore)
        await fulfillment(of: [loadMoreExpectation], timeout: 2.0)

        XCTAssertEqual(repository.observeProductItemsByPageCallCount, 2)
        XCTAssertEqual(recordedStates, [
            .start,
            .runningTask(.refresh),
            .resultTask(ProductListConfig(ids: [1], reconfigIds: [1]), task: .refresh),
            .endTask,
            .runningTask(.loadMore),
            .resultTask(ProductListConfig(ids: [1, 2], reconfigIds: []), task: .loadMore),
            .resultTask(ProductListConfig(ids: [1, 2], reconfigIds: [2]), task: .loadMore),
            .endTask
        ])
        XCTAssertEqual(sut.getProductItem(id: 1), item1)
        XCTAssertEqual(sut.getProductItem(id: 2), loadMoreNetworkItem)
        XCTAssertEqual(sut.getTotalProductsCount(), 10)
    }

    // MARK: - Selection & Coordinator Tests
    func testDidSelectProduct_invokesCoordinatorShowProductDetailScreen() {
        sut.didSelectProduct(id: 42)

        XCTAssertEqual(coordinator.showProductDetailScreenCallCount, 1)
        XCTAssertEqual(coordinator.lastSelectedProductId, 42)
    }
}

// MARK: - Helper Methods
extension ProductListViewModelTests {
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
}
