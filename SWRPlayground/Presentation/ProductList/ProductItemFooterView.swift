//
//  ProductItemFooterView.swift
//  ProductCatalog
//
//  Created by Fadhil Ikhsanta's Personal on 20/09/26.
//

import UIKit
import SnapKit

final class ProductItemFooterView: UITableViewHeaderFooterView {
    // MARK: - Identifier
    static let reuseIdentifier = "ProductItemFooterView"

    // MARK: - Properties
	private let placeholder = "\t\t\t\t"
	
    // MARK: - Views
    private lazy var messageLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
		label.text = placeholder
        return label
    }()

    // MARK: - Overrides
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Support methods
extension ProductItemFooterView {
    private func setupViews() {
        contentView.addSubview(messageLabel)

        messageLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(12)
        }
    }
}

extension ProductItemFooterView {
	func showIdle() {
		messageLabel.text = placeholder
	}
	
	func showRunningTask(_ task: ProductListTask) {
		switch task {
		case .refresh:
			messageLabel.text = "Refresh products..."
		case .loadMore:
			messageLabel.text = "Load more products..."
		}
	}
	
	func showResultTask(count: Int, totalProductsCount: Int) {
		if count == 0 && totalProductsCount == 0 {
			messageLabel.text = "No products found."
		} else {
			messageLabel.text = "Showing \(count) of \(totalProductsCount) products."
		}
	}
	
	func showErrorMessage(_ message: String) {
		messageLabel.text = message
	}
}
