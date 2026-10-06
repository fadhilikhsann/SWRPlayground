//
//  ProductItemTableViewCell.swift
//  SWRPlayground
//
//  Created by Fadhil Ikhsanta's Personal on 25/09/26.
//

import UIKit
import SnapKit

final class ProductItemTableViewCell: UITableViewCell {
    static let reuseIdentifier = "ProductItemTableViewCell"

	private let titlePlaceholder = "\t\t\t\t\t\t\t\t"
	private let categoryPlaceholder = "\t\t\t\t\t\t"
	private let pricePlaceholder = "\t\t\t\t"
	
	private lazy var imageLoadingIndicator: UIActivityIndicatorView = {
		let indicator = UIActivityIndicatorView(style: .medium)
		indicator.hidesWhenStopped = true
		return indicator
	}()
	
    private lazy var thumbnailImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = .secondarySystemBackground
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 12
        imageView.clipsToBounds = true
        imageView.tintColor = .tertiaryLabel
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 1
        return label
    }()

    private lazy var categoryLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .secondaryLabel
        label.numberOfLines = 1
        return label
    }()

    private lazy var priceLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .systemBlue
		label.numberOfLines = 1
        return label
    }()

    private lazy var labelsStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [titleLabel, categoryLabel, priceLabel])
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 7
        return stackView
    }()

    private var imageTask: Task<Void, Never>?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        setIdle()
    }

	func configure(with product: ProductItem, imageLoader: ImageLoading) {
		titleLabel.backgroundColor = .clear
		categoryLabel.backgroundColor = .clear
		priceLabel.backgroundColor = .clear

        titleLabel.text = product.title
        categoryLabel.text = product.category.capitalized
        priceLabel.text = priceFormatter.string(from: NSNumber(value: product.price))

        guard let url = product.thumbnailURL else { return }
        imageTask = Task { [weak self] in
			guard let self else { return }
			
            do {
                let image = try await imageLoader.loadImage(from: url)
                try Task.checkCancellation()
				imageLoadingIndicator.stopAnimating()
				thumbnailImageView.image = image
            } catch is CancellationError {
				/// Do nothing
            } catch {
				/// Do nothing
            }
			
			imageTask = nil
        }
    }
	
	func setIdle() {
		cancelImageTask()
		
		titleLabel.backgroundColor = .secondarySystemBackground
		categoryLabel.backgroundColor = .secondarySystemBackground
		priceLabel.backgroundColor = .secondarySystemBackground
		
		titleLabel.text = titlePlaceholder
		categoryLabel.text = categoryPlaceholder
		priceLabel.text = pricePlaceholder
		
		thumbnailImageView.image = nil
		imageLoadingIndicator.startAnimating()
	}

    private func configureView() {
        selectionStyle = .none
        contentView.addSubview(thumbnailImageView)
        contentView.addSubview(labelsStackView)

        thumbnailImageView.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(16)
            make.bottom.lessThanOrEqualToSuperview().inset(16)
            make.size.equalTo(100)
        }
		
		thumbnailImageView.addSubview(imageLoadingIndicator)
		imageLoadingIndicator.snp.makeConstraints { make in
			make.center.equalTo(thumbnailImageView)
		}

        labelsStackView.snp.makeConstraints { make in
            make.leading.equalTo(thumbnailImageView.snp.trailing).offset(16)
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalTo(thumbnailImageView)
            make.top.greaterThanOrEqualToSuperview().inset(16)
            make.bottom.lessThanOrEqualToSuperview().inset(16)
        }
    }

    private let priceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }()
	
	private func cancelImageTask() {
		imageTask?.cancel()
		imageTask = nil
	}
}
