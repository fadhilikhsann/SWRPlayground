//
//  ProductListViewModel.swift
//  Product Catalog v3
//
//  Created by Fadhil Ikhsanta's Personal on 25/09/26.
//

import Combine
import Foundation

@MainActor
protocol ProductListViewModelProtocol: AnyObject {
	var statePublisher: AnyPublisher<TableViewState<ProductListTask, ProductListConfig>, Never> { get }
	
	func start()
	func request(_ task: ProductListTask)
	
	func getProductItem(id: Int) -> ProductItem?
	func getTotalProductsCount() -> Int
	
	func didSelectProduct(id: Int)
}

@MainActor
final class ProductListViewModel: ProductListViewModelProtocol {
	typealias STATE = TableViewState<ProductListTask, ProductListConfig>
	
	weak var coordinator: AppCoordinatorDelegate?
	
	@Published private var state: STATE = .start
	var statePublisher: AnyPublisher<STATE, Never> {
		$state.eraseToAnyPublisher()
	}
	
	//	private var cancellables: Set<AnyCancellable> = []
	//
	//	private let loadTaskThrottlePublisher: PassthroughSubject<ListViewTask, Never> = .init()
	
	private var loadTask: Task<Void, Never>?
	
	private var products: [ProductItem] = []
	private var productIndexesById: [ProductItem.ID: Int] = [:]
	private var totalProductsCount = 0
	
	private let repository: ProductRepository
	private let pageSize: Int
	init(pageSize: Int = 20, repository: ProductRepository) {
		self.pageSize = pageSize
		self.repository = repository
		//		bindingPublisher()
	}
	
	deinit {
		loadTask?.cancel()
	}
	
	//	private func bindingPublisher() {
	//		loadTaskThrottlePublisher
	//			.throttle(for: .milliseconds(300), scheduler: RunLoop.main, latest: true)
	//			.sink { [weak self] task in
	//				guard let self else { return }
	//				executeTaskIfNeeded(task)
	//			}
	//			.store(in: &cancellables)
	//	}
	
	func start() {
		guard state == .start else { return }
		executeTaskIfNeeded(.refresh)
	}
	
	func request(_ task: ProductListTask) {
		//		loadTaskThrottlePublisher.send(task)
		executeTaskIfNeeded(task)
	}
	
	func getProductItem(id: Int) -> ProductItem? {
		guard let index = productIndexesById[id] else { return nil }
		return products[index]
	}
	
	func getTotalProductsCount() -> Int {
		totalProductsCount
	}
	
	func didSelectProduct(id: Int) {
		coordinator?.showProductDetailScreen(productId: id)
	}
}

extension ProductListViewModel {
	private func executeTaskIfNeeded(_ task: ProductListTask) {
		guard pageSize > 0 else {
			state = .endTask
			return
		}
		
		switch task {
		case .refresh:
			executeLoadRefresh()
			
		case .loadMore:
			switch state {
			case .runningTask:
				return
			case .resultTask(_, let task) where task == .refresh:
				return
			default:
				break
			}
			
			let productsCount = products.count
			guard productsCount > 0 && productsCount < totalProductsCount else { return }
			
			executeLoadMore()
		}
	}
	
	private func executeLoadRefresh() {
		loadTask?.cancel()
		
		let task = ProductListTask.refresh
		state = .runningTask(task)
		
		loadTask = Task { [weak self] in
			guard let self else { return }
			
			let request = PageRequest(limit: pageSize, skip: 0)
			
			do {
				var reset = true
				
				for try await resource in repository.observeProductItemsByPage(for: request) {
					try Task.checkCancellation()
					
					totalProductsCount = resource.total
					
					if reset {
						resetProducts(with: resource.products, task: task)
						reset = false
						continue
					}
					
					mergingCurrentProducts(with: resource.products, task: task)
				}
			} catch is CancellationError {
				/// End task
			} catch {
				if products.isEmpty {
					state = .errorMessage(error.localizedDescription)
				}
			}
			
			state = .endTask
			
			loadTask = nil
		}
	}
	
	private func executeLoadMore() {
		loadTask?.cancel()
		
		let task = ProductListTask.loadMore
		state = .runningTask(task)
		
		loadTask = Task { [weak self] in
			guard let self else { return }
			
			let skip = products.count
			let request = PageRequest(limit: pageSize, skip: skip)
			
			do {
				for try await resource in repository.observeProductItemsByPage(for: request) {
					try Task.checkCancellation()
					
					totalProductsCount = resource.total
					mergingCurrentProducts(with: resource.products, task: task)
				}
			} catch is CancellationError {
				/// End task
			} catch {
				if products.isEmpty {
					state = .errorMessage(error.localizedDescription)
				}
			}
			
			state = .endTask
			
			loadTask = nil
		}
	}
}

extension ProductListViewModel {
	private func resetProducts(
		with incomingProducts: [ProductItem],
		task: ProductListTask
	) {
		products = incomingProducts
		productIndexesById = Dictionary(
			uniqueKeysWithValues: products
				.enumerated()
				.map { ($1.id, $0) }
		)
		
		let ids = products.map(\.id)
		
		state = .resultTask(ProductListConfig(ids: ids, reconfigIds: ids), task: task)
	}
	
	private func mergingCurrentProducts(
		with incomingProducts: [ProductItem],
		task: ProductListTask
	) {
		var reconfigIds: [ProductItem.ID] = []
		
		let oldProductsCount = products.count
		
		for incomingProduct in incomingProducts {
			if let currentProductIndex = productIndexesById[incomingProduct.id] {
				if products[currentProductIndex] != incomingProduct {
					products[currentProductIndex] = incomingProduct
					reconfigIds.append(incomingProduct.id)
				}
			} else {
				productIndexesById[incomingProduct.id] = products.endIndex
				products.append(incomingProduct)
			}
		}
		
		let ids = products.map(\.id)
		
		if !reconfigIds.isEmpty || oldProductsCount < products.count {
			state = .resultTask(ProductListConfig(ids: ids, reconfigIds: reconfigIds), task: task)
		}
	}
}
