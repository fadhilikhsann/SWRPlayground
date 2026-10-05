import UIKit

//
//  AppCoordinator.swift
//  Product Catalog v3
//
//  Created by Fadhil Ikhsanta's Personal on 25/09/26.
//

@MainActor
protocol AppCoordinatorDelegate: AnyObject {
	func start()
	func showProductDetailScreen(productId: Int)
}

@MainActor
final class AppCoordinator {
	private let navigationController: UINavigationController
	
	private lazy var productCache = ProductCache()
	private lazy var imageCache = ImageCache()
	
	private lazy var imageLoader = ImageLoader(cache: imageCache)
	
	private lazy var apiClient = DefaultProductAPIClient()
	private lazy var repository = DefaultProductRepository(apiClient: apiClient, cache: productCache)
	
	init(navigationController: UINavigationController) {
		self.navigationController = navigationController
	}
}

extension AppCoordinator: AppCoordinatorDelegate {
    func start() {
        let viewModel = ProductListViewModel(repository: repository)
		let viewController = ProductListViewController(viewModel: viewModel, imageLoader: imageLoader)
		
		viewModel.coordinator = self
		
		navigationController.pushViewController(viewController, animated: true)
    }
	
	func showProductDetailScreen(productId: Int) {
		let viewModel = ProductDetailViewModel(id: productId, repository: repository)
		let viewController = ProductDetailViewController(viewModel: viewModel, imageLoader: imageLoader)
		
		viewModel.coordinator = self
		
		navigationController.pushViewController(viewController, animated: true)
	}
}
