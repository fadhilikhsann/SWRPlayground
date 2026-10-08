//
//  ProductDetailViewModel.swift
//  SWRPlayground
//
//  Created by Fadhil Ikhsanta's Personal on 28/09/26.
//

import Foundation
import Combine

// MARK: - Protocol
@MainActor
protocol ProductDetailViewModelProtocol: AnyObject {
	var statePublisher: AnyPublisher<TableViewState<ProductDetailTask, [ProductDetailRow]>, Never> { get }
	
    func getImageURLs() -> [URL]
    func getTitle() -> String?
    func getCategory() -> String?
    func getPrice() -> Double?
    func getDescription() -> String?
	
	func refresh()
}

@MainActor
final class ProductDetailViewModel {
    // MARK: - Typealiases
    typealias STATE = TableViewState<ProductDetailTask, [ProductDetailRow]>
    
    // MARK: - Properties
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
    
    private var imageURLs: [URL] = []
    private var title: String?
    private var category: String?
    private var price: Double?
    private var description: String?
    
    @Published private var state: STATE = .start
    
    private var loadTask: Task<Void, Never>?
    
    private let repository: ProductRepository
    
    // MARK: - Init
    init(id: Int, repository: ProductRepository) {
        self.id = id
        self.repository = repository
    }
    
    deinit {
        loadTask?.cancel()
        loadTask = nil
    }
}

// MARK: - Conforms protocol
extension ProductDetailViewModel: ProductDetailViewModelProtocol {
    var statePublisher: AnyPublisher<STATE, Never> {
        $state.eraseToAnyPublisher()
    }
    
    func getImageURLs() -> [URL] {
        imageURLs
    }
    
    func getTitle() -> String? {
        title
    }
    
    func getCategory() -> String? {
        category
    }
    
    func getPrice() -> Double? {
        price
    }
    
    func getDescription() -> String? {
        description
    }
    
	func refresh() {
		loadTask?.cancel()
        loadTask = nil
		
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
                if productDetail == nil {
                    state = .errorMessage(error.localizedDescription)
                }
			}
            
            state = .endTask
            loadTask = nil
		}
	}
}
