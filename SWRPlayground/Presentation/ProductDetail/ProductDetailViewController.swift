//
//  ProductDetailViewController.swift
//  SWRPlayground
//
//  Created by Fadhil Ikhsanta's Personal on 28/09/26.
//

import UIKit
import SnapKit
import Combine

class ProductDetailViewController: UITableViewController {
    // MARK: - Typealiases
	typealias DATASOURCE = UITableViewDiffableDataSource<DefaultSection, ProductDetailRow>
	typealias STATE = TableViewState<ProductDetailTask, [ProductDetailRow]>
	
    // MARK: - Properties
	private lazy var dataSource: DATASOURCE = {
		let dataSource = DATASOURCE(tableView: tableView, cellProvider: makeCellProvider)
		dataSource.defaultRowAnimation = .fade
		return dataSource
	}()
	
	private var cancellables = Set<AnyCancellable>()
	
	private let viewModel: ProductDetailViewModelProtocol
	private let imageLoader: ImageLoading
    
    // MARK: - Init
	init(
		viewModel: ProductDetailViewModelProtocol,
		imageLoader: ImageLoading
	) {
		self.viewModel = viewModel
		self.imageLoader = imageLoader
        super.init(style: .plain)
	}
	
	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
    // MARK: - Overrides
	override func viewDidLoad() {
		super.viewDidLoad()
		configureView()
		bindingViewModel()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		navigationController?.navigationBar.prefersLargeTitles = false
	}
}

// MARK: - Support methods
extension ProductDetailViewController  {
	private func configureView() {
        /// NavigationBar
		title = "Product Details"
		
        /// TableView
        tableView.register(ProductImageTableViewCell.self, forCellReuseIdentifier: ProductImageTableViewCell.reuseIdentifier)
        tableView.register(ProductDetailTableViewCell.self, forCellReuseIdentifier: ProductDetailTableViewCell.reuseIdentifier)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = UITableView.automaticDimension
        
        tableView.separatorStyle = .none
        
        tableView.sectionHeaderTopPadding = 0
        
        /// RefreshControl
        let refreshControl = UIRefreshControl()
		
		refreshControl.addAction(.init(handler: { [weak self] _ in
			guard let self else { return }
			viewModel.refresh()
		}), for: .valueChanged)
		
        self.refreshControl = refreshControl
	}
	
	private func bindingViewModel() {
		viewModel.statePublisher
			.receive(on: DispatchQueue.main)
			.sink { [weak self] state in
				guard let self else { return }
				render(state: state)
			}
			.store(in: &cancellables)
	}
	
	private func makeCellProvider(
		_ tableView: UITableView,
		_ indexPath: IndexPath,
		_ row: ProductDetailRow
	) -> UITableViewCell? {
		switch row {
		case .image:
			guard let cell = tableView.dequeueReusableCell(
				withIdentifier: ProductImageTableViewCell.reuseIdentifier,
				for: indexPath
			) as? ProductImageTableViewCell else {
				return nil
			}
			cell.configure(viewModel.getImageURLs(), imageLoader: imageLoader)
			return cell
		case .detail:
			guard let cell = tableView.dequeueReusableCell(
				withIdentifier: ProductDetailTableViewCell.reuseIdentifier,
				for: indexPath
			) as? ProductDetailTableViewCell else {
				return nil
			}
			cell.configure(
				title: viewModel.getTitle(),
				category: viewModel.getCategory(),
				price: viewModel.getPrice(),
				description: viewModel.getDescription()
			)
			return cell
		}
	}
	
	private func applySnapshot(reconfigRows: [ProductDetailRow] = []) {
		var snapshot = NSDiffableDataSourceSnapshot<DefaultSection, ProductDetailRow>()
		snapshot.appendSections([.main])
		
		snapshot.appendItems([.image, .detail], toSection: .main)
		snapshot.reconfigureItems(reconfigRows)
		
		dataSource.apply(snapshot, animatingDifferences: false)
	}
	
	private func render(state: STATE) {
		switch state {
		case .start:
			applySnapshot()
			viewModel.refresh()
			
		case .runningTask(_):
			break
			
		case .resultTask(let rows, _):
			applySnapshot(reconfigRows: rows)
			
		case .endTask:
			refreshControl?.endRefreshing()
			
		case .errorMessage(let message):
			showNonBlockingError(message)
		}
	}
	
	private func showNonBlockingError(_ message: String) {
		guard presentedViewController == nil else { return }
		let alert = UIAlertController(
			title: "Pembaruan gagal",
			message: message,
			preferredStyle: .alert
		)
		alert.addAction(UIAlertAction(title: "Close", style: .default))
		present(alert, animated: true)
	}
}
