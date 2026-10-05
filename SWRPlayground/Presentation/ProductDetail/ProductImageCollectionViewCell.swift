//
//  ProductImageCollectionViewCell.swift
//  Product Catalog v3
//
//  Created by Fadhil Ikhsanta's Personal on 28/09/26.
//

import UIKit
import SnapKit

class ProductImageCollectionViewCell: UICollectionViewCell {
	static let reuseIdentifier = "ProductImageCollectionViewCell"
	
	private lazy var imageLoadingIndicator: UIActivityIndicatorView = {
		let indicator = UIActivityIndicatorView(style: .large)
		indicator.hidesWhenStopped = true
		return indicator
	}()
	
	private lazy var productImageView: UIImageView = {
		let imageView = UIImageView()
		imageView.backgroundColor = .secondarySystemBackground
		imageView.contentMode = .scaleAspectFill
		imageView.clipsToBounds = true
		return imageView
	}()
	
	private var imageTask: Task<Void, Never>?
	
	override init(frame: CGRect) {
		super.init(frame: frame)
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

extension ProductImageCollectionViewCell {
	private func configureView() {
		contentView.addSubview(productImageView)
		productImageView.snp.makeConstraints { make in
			make.top.leading.trailing.equalToSuperview()
			make.height.equalTo(productImageView.snp.width)
			make.bottom.equalToSuperview()
		}
		
		productImageView.addSubview(imageLoadingIndicator)
		imageLoadingIndicator.snp.makeConstraints { make in
			make.center.equalToSuperview()
		}
		
		imageLoadingIndicator.startAnimating()
	}
}

extension ProductImageCollectionViewCell {
	func configure(_ url: URL, imageLoader: ImageLoading) {
		imageLoadingIndicator.stopAnimating()
		
		imageTask = Task { [weak self] in
			guard let self else { return }
			
			do {
				let image = try await imageLoader.loadImage(from: url)
				try Task.checkCancellation()
				imageLoadingIndicator.stopAnimating()
				productImageView.image = image
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
		
		productImageView.image = nil
		imageLoadingIndicator.startAnimating()
	}
	
	private func cancelImageTask() {
		imageTask?.cancel()
		imageTask = nil
	}
}
