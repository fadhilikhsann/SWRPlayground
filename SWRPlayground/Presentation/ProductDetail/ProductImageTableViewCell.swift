//
//  ProductImagesTableViewCell.swift
//  SWRPlayground
//
//  Created by Fadhil Ikhsanta's Personal on 28/09/26.
//

import UIKit
import SnapKit

final class ProductImageTableViewCell: UITableViewCell {
    static let reuseIdentifier = "ProductImageTableViewCell"
	
	typealias DATASOURCE = UICollectionViewDiffableDataSource<DefaultSection, ImageRow>
	
	private lazy var dataSource = DATASOURCE(collectionView: collectionView, cellProvider: makeCellProvider)

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(
            ProductImageCollectionViewCell.self,
            forCellWithReuseIdentifier: ProductImageCollectionViewCell.reuseIdentifier
        )
		
        return collectionView
    }()
	
	private lazy var pageControl: UIPageControl = {
		let pageControl = UIPageControl()
		
		pageControl.hidesForSinglePage = true
		
		pageControl.pageIndicatorTintColor = .systemGray4
		pageControl.currentPageIndicatorTintColor = .label
		
		pageControl.addAction(
			.init(handler: { [weak self] _ in
				guard let self else { return }
				let currentPage = pageControl.currentPage
				scrollToPage(currentPage)
			}),
			for: .valueChanged
		)
		
		return pageControl
	}()
	
	private var imageLoader: ImageLoading?

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

	func configure(_ urls: [URL], imageLoader: ImageLoading) {
		self.imageLoader = imageLoader
		
		if !urls.isEmpty {
			applySnapshot(with: urls)
			return
		}
		
		applySnapshot()
    }
	
	func setIdle() {
		applySnapshot()
	}
}

extension ProductImageTableViewCell {
    private func configureView() {
        selectionStyle = .none
		
        contentView.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(collectionView.snp.width)
            make.bottom.equalToSuperview()
        }
		
		contentView.addSubview(pageControl)
		pageControl.snp.makeConstraints { make in
			make.centerX.equalToSuperview()
			make.bottom.equalToSuperview().inset(8)
		}
    }
	
	private func makeCellProvider(
		_ collectionView: UICollectionView,
		_ indexPath: IndexPath,
		_ row: ImageRow
	) -> ProductImageCollectionViewCell? {
		guard let imageLoader,
			  let cell = collectionView.dequeueReusableCell(
			withReuseIdentifier: ProductImageCollectionViewCell.reuseIdentifier,
			for: indexPath
		) as? ProductImageCollectionViewCell else {
			return nil
		}
		
		switch row {
		case .skeleton:
			cell.setIdle()
		case .image(let url):
			cell.configure(url, imageLoader: imageLoader)
		}
		
		return cell
	}

    private func applySnapshot(with urls: [URL] = []) {
        var snapshot = NSDiffableDataSourceSnapshot<DefaultSection, ImageRow>()
        snapshot.appendSections([.main])
		
		var items: [ImageRow] = []
		if urls.isEmpty {
			items = [ImageRow.skeleton(0)]
		} else {
			items = urls.map(ImageRow.image)
		}
		
        snapshot.appendItems(items)
		dataSource.apply(snapshot, animatingDifferences: false) { [weak self] in
			guard let self else { return }
			updatePageControl()
		}
    }
	
	private func scrollToPage(_ page: Int) {
		let snapshot = dataSource.snapshot()
		let numberOfItems = snapshot.numberOfItems
		
		guard page >= 0, page < numberOfItems else { return }
		
		collectionView.scrollToItem(
			at: IndexPath(item: page, section: 0),
			at: .centeredHorizontally,
			animated: true
		)
	}
	
	func updatePageControl() {
		let snapshot = dataSource.snapshot()
		
		guard let sectionId = snapshot.sectionIdentifiers.first, case .main = sectionId else { return }
		let numberOfItems = snapshot.numberOfItems(inSection: sectionId)
		
		pageControl.numberOfPages = numberOfItems
		pageControl.currentPage = min(pageControl.currentPage, max(numberOfItems - 1, 0))
	}
}

extension ProductImageTableViewCell: UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        collectionView.bounds.size
    }
	
	func scrollViewDidScroll(_ scrollView: UIScrollView) {
		guard scrollView === collectionView else {
			return
		}
		
		let pageWidth = collectionView.bounds.width
		let numberOfPages = pageControl.numberOfPages
		
		guard pageWidth > 0, numberOfPages > 0 else { return }
		
		let offsetX = collectionView.contentOffset.x + collectionView.adjustedContentInset.left
		
		let calculatedPage = Int(round(offsetX / pageWidth))
		
		pageControl.currentPage = min(max(calculatedPage, 0), numberOfPages - 1)
	}
}
