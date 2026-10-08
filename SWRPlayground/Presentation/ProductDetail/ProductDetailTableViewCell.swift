//
//  ProductDetailsTableViewCell.swift
//  SWRPlayground
//
//  Created by Fadhil Ikhsanta's Personal on 28/09/26.
//

import UIKit
import SnapKit

class ProductDetailTableViewCell: UITableViewCell {
    // MARK: - Identifier
	static let reuseIdentifier = "ProductDetailTableViewCell"
	
	// MARK: - Properties
	private let titlePlaceholder = "\t\t\t\t\t\t\t\t"
	private let categoryPlaceholder = "\t\t\t\t\t\t"
	private let pricePlaceholder = "\t\t\t\t"
	private let descriptionPlaceholder = "\t\t\t\t\t\t\t\t\t\t"
	
    // MARK: - Views
	private lazy var titleLabel: UILabel = {
		let label = UILabel()
		label.text = titlePlaceholder
		label.font = .preferredFont(forTextStyle: .title1)
		label.numberOfLines = 1
		label.backgroundColor = .secondarySystemBackground
		return label
	}()
	
	private lazy var categoryLabel: UILabel = {
		let label = UILabel()
		label.text = categoryPlaceholder
		label.font = .preferredFont(forTextStyle: .caption1)
		label.textColor = .secondaryLabel
		label.backgroundColor = .secondarySystemBackground
		return label
	}()
	
	private lazy var priceLabel: UILabel = {
		let label = UILabel()
		label.text = pricePlaceholder
		label.font = .preferredFont(forTextStyle: .headline)
		label.textColor = .systemBlue
		label.backgroundColor = .secondarySystemBackground
		return label
	}()
	
	private lazy var descriptionLabel: UILabel = {
		let label = UILabel()
		label.text = descriptionPlaceholder
		label.font = .preferredFont(forTextStyle: .body)
		label.backgroundColor = .secondarySystemBackground
		label.numberOfLines = 0
		return label
	}()
	
	// MARK: - Overrides
	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		configureView()
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func prepareForReuse() {
		super.prepareForReuse()
		setIdle()
	}
}

// MARK: - Support methods
extension ProductDetailTableViewCell {
	private func configureView() {
		selectionStyle = .none
		
		contentView.addSubview(titleLabel)
		titleLabel.snp.makeConstraints { make in
			make.leading.equalToSuperview().offset(16)
			make.trailing.equalToSuperview().inset(16)
			make.top.equalToSuperview().offset(16)
		}
		
		contentView.addSubview(categoryLabel)
		categoryLabel.snp.makeConstraints { make in
			make.leading.equalTo(titleLabel)
			make.top.equalTo(titleLabel.snp.bottom).offset(6)
		}
		
		contentView.addSubview(priceLabel)
		priceLabel.snp.makeConstraints { make in
			make.leading.equalTo(categoryLabel)
			make.top.equalTo(categoryLabel.snp.bottom).offset(6)
		}
		
		contentView.addSubview(descriptionLabel)
		descriptionLabel.snp.makeConstraints { make in
			make.leading.trailing.equalTo(titleLabel)
			make.top.equalTo(priceLabel.snp.bottom).offset(18)
			make.bottom.greaterThanOrEqualToSuperview().inset(16)
		}
	}
}

extension ProductDetailTableViewCell {
	func configure(
		title: String?,
		category: String?,
		price: Double?,
		description: String?
	) {
		if let title, !title.isEmpty {
			titleLabel.backgroundColor = .clear
			titleLabel.text = title
		} else {
			setTitleLabelIdle()
		}
		
		if let category, !category.isEmpty {
			categoryLabel.backgroundColor = .clear
			categoryLabel.text = category.capitalized
		} else {
			setCategoryLabelIdle()
		}
		
		if let price, !price.isNaN {
			priceLabel.backgroundColor = .clear
			priceLabel.text = price.formatted(
				.currency(code: "USD").precision(.fractionLength(2))
			)
		} else {
			setPriceLabelIdle()
		}
		
		if let description, !description.isEmpty {
			descriptionLabel.backgroundColor = .clear
			descriptionLabel.text = description
		} else {
			setDescriptionLabelIdle()
		}
	}
	
	private func setIdle() {
		setTitleLabelIdle()
		setCategoryLabelIdle()
		setPriceLabelIdle()
		setDescriptionLabelIdle()
	}
	
	private func setTitleLabelIdle() {
		titleLabel.backgroundColor = .secondarySystemBackground
		titleLabel.text = titlePlaceholder
	}
	
	private func setCategoryLabelIdle() {
		categoryLabel.backgroundColor = .secondarySystemBackground
		categoryLabel.text = categoryPlaceholder
	}
	
	private func setPriceLabelIdle() {
		priceLabel.backgroundColor = .secondarySystemBackground
		priceLabel.text = pricePlaceholder
	}
	
	private func setDescriptionLabelIdle() {
		descriptionLabel.backgroundColor = .secondarySystemBackground
		descriptionLabel.text = descriptionPlaceholder
	}
}
