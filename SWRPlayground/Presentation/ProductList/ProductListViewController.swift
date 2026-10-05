//
//  ProductListViewController.swift
//  Product Catalog v3
//
//  Created by Fadhil Ikhsanta's Personal on 25/09/26.
//

import UIKit
import SnapKit
import Combine

final class ProductListViewController: UIViewController {
	typealias DATASOURCE = UITableViewDiffableDataSource<DefaultSection, ProductItemRow>
	typealias STATE = TableViewState<ProductListTask, ProductListConfig>
	
	private lazy var dataSource: DATASOURCE = {
		let dataSource = DATASOURCE(tableView: tableView, cellProvider: makeCellProvider)
		dataSource.defaultRowAnimation = .fade
		return dataSource
	}()
	
	private var cancellables = Set<AnyCancellable>()
	
	private lazy var tableView: UITableView = {
		let tableView = UITableView(frame: .zero, style: .plain)
		tableView.separatorInset = UIEdgeInsets(top: 0, left: 132, bottom: 0, right: 16)
		
		tableView.delegate = self
		
		tableView.register(ProductItemTableViewCell.self, forCellReuseIdentifier: ProductItemTableViewCell.reuseIdentifier)
		tableView.rowHeight = UITableView.automaticDimension
		tableView.estimatedRowHeight = UITableView.automaticDimension
		
		tableView.register(
			ProductItemFooterView.self,
			forHeaderFooterViewReuseIdentifier: ProductItemFooterView.reuseIdentifier
		)
		tableView.sectionFooterHeight = UITableView.automaticDimension
		tableView.estimatedSectionFooterHeight = UITableView.automaticDimension
		
		return tableView
	}()
	
	private lazy var refreshControl = UIRefreshControl()
	
	private let viewModel: ProductListViewModelProtocol
	private let imageLoader: ImageLoading
	init(
		viewModel: ProductListViewModelProtocol,
		imageLoader: ImageLoading
	) {
		self.viewModel = viewModel
		self.imageLoader = imageLoader
		super.init(nibName: nil, bundle: nil)
	}
	
	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		configureView()
		bindingViewModel()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		navigationController?.navigationBar.prefersLargeTitles = true
	}
}

extension ProductListViewController {
    private func configureView() {
        title = "Product Catalog"

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

		refreshControl.addAction(.init(handler: { [weak self] _ in
			guard let self else { return }
			viewModel.request(.refresh)
		}), for: .valueChanged)
		
        tableView.refreshControl = refreshControl
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
		_ row: ProductItemRow
	) -> ProductItemTableViewCell? {
		guard let cell = tableView.dequeueReusableCell(
				withIdentifier: ProductItemTableViewCell.reuseIdentifier,
				for: indexPath
			  ) as? ProductItemTableViewCell else {
			return nil
		}
		
		switch row {
		case .skeleton:
			cell.setIdle()
		case .item(let id):
			if let product = viewModel.getProductItem(id: id) {
				cell.configure(with: product, imageLoader: imageLoader)
			} else {
				cell.setIdle()
			}
		}
		
		return cell
	}
	
	private func applySnapshot(ids: [Int] = [], reconfigIds: [Int] = []) {
		var snapshot = NSDiffableDataSourceSnapshot<DefaultSection, ProductItemRow>()
		snapshot.appendSections([.main])
		
		if ids.isEmpty {
			let rows = (0..<20).map(ProductItemRow.skeleton)
			snapshot.appendItems(rows, toSection: .main)
		} else {
			let rows = ids.map(ProductItemRow.item)
			snapshot.appendItems(rows, toSection: .main)
			snapshot.reconfigureItems(reconfigIds.map(ProductItemRow.item))
		}
		
		dataSource.apply(snapshot, animatingDifferences: ids.isEmpty)
	}
	
    private func render(state: STATE) {
        switch state {
		case .start:
			applySnapshot()
			viewModel.start()
			
		case .runningTask(let task):
			switch task {
			case .refresh:
				break
			case .loadMore:
				refreshControl.endRefreshing()
			}
			
		case .resultTask(let config, _):
			applySnapshot(ids: config.ids, reconfigIds: config.reconfigIds)
			
		case .endTask:
			refreshControl.endRefreshing()
			
		case .errorMessage(let message):
			showNonBlockingError(message)
		}
		
		setupFooterView(state: state)
    }

	private func setupFooterView(state: STATE) {
		let section = 0
		
		guard let footerView = tableView.footerView(forSection: section) as? ProductItemFooterView else {
			return
		}
		
		switch state {
		case .start:
			footerView.showIdle()
		case .runningTask(let task):
			footerView.showRunningTask(task)
		case .resultTask(_, _):
			break
		case .endTask:
			guard let sectionId = dataSource.snapshot().sectionIdentifiers[safe: section],
				  case .main = sectionId else {
				return
			}
			
			let productsCount = dataSource.snapshot().itemIdentifiers(inSection: sectionId).count
			let totalProductsCount = viewModel.getTotalProductsCount()
			
			footerView.showResultTask(count: productsCount, totalProductsCount: totalProductsCount)
		case .errorMessage(let message):
			footerView.showErrorMessage(message)
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

extension ProductListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		let snapshot = dataSource.snapshot()
		guard let sectionId = snapshot.sectionIdentifiers[safe: indexPath.section] else { return }
		
		guard case .main = sectionId else { return }
		
		let rows = snapshot.itemIdentifiers(inSection: sectionId)
		
		let thresholdIndex = max(0, rows.count - 5)
		if indexPath.row >= thresholdIndex, case .item(_) = rows[thresholdIndex] {
			viewModel.request(.loadMore)
		}
    }
	
	func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
		guard let sectionId = dataSource.snapshot().sectionIdentifiers[safe: section],
			  case .main = sectionId else {
			return nil
		}
		
		guard let footerView = tableView.dequeueReusableHeaderFooterView(
			withIdentifier: ProductItemFooterView.reuseIdentifier
		) as? ProductItemFooterView else {
			return nil
		}
		
		return footerView
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let snapshot = dataSource.snapshot()
		let section = indexPath.section
		let row = indexPath.row
		
		guard let sectionId = snapshot.sectionIdentifiers[safe: section],
			  case .main = sectionId,
			  let row = snapshot.itemIdentifiers(inSection: sectionId)[safe: row],
			  case .item(let id) = row
		else {
			return
		}
		
		viewModel.didSelectProduct(id: id)
	}
}
