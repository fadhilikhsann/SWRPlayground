//
//  ProductDetailViewModel.swift
//  Product Catalog v3
//
//  Created by Fadhil Ikhsanta's Personal on 28/09/26.
//

import Foundation
import Combine

@MainActor
protocol ProductDetailViewModelProtocol: AnyObject {
	var statePublisher: AnyPublisher<TableViewState<ProductDetailTask, [ProductDetailRow]>, Never> { get }
	
	var imageURLs: [URL] { get }
	var title: String? { get }
	var category: String? { get }
	var price: Double? { get }
	var description: String? { get }
	
	func refresh()
}

@MainActor
final class ProductDetailViewModel: ProductDetailViewModelProtocol {
	typealias STATE = TableViewState<ProductDetailTask, [ProductDetailRow]>
	
	weak var coordinator: AppCoordinatorDelegate?
	
	private let id: Int
	
	private var productDetail: ProductDetail? {
		willSet {
			imageURLs = newValue?.imageURLs ?? []
			title = newValue?.title
			category = newValue?.category
			price = newValue?.price
			description = newValue?.description
		}
	}
	
	private(set) var imageURLs: [URL] = []
	private(set) var title: String?
	private(set) var category: String?
	private(set) var price: Double?
	private(set) var description: String?
	
	@Published private var state: STATE = .start
	var statePublisher: AnyPublisher<STATE, Never> {
		$state.eraseToAnyPublisher()
	}
	
	private var loadTask: Task<Void, Never>?
	
	private let repository: ProductRepository
	init(id: Int, repository: ProductRepository) {
		self.id = id
		self.repository = repository
	}
	
	func refresh() {
		loadTask?.cancel()
		
		state = .runningTask(.refresh)
		
		loadTask = Task { [weak self] in
			guard let self else { return }
			
			do {
				for try await resource in repository.observeProductDetail(id: id) {
					try Task.checkCancellation()
					
					if productDetail != resource {
						productDetail = resource
						state = .resultTask([.image, .detail], task: .refresh)
					}
				}
			} catch is CancellationError {
				/// End task
			} catch {
				/// End task
			}
			
			state = .endTask
			
			loadTask = nil
		}
	}
}
