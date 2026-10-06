//
//  ProductDetailDTO.swift
//  SWRPlayground
//
//  Created by Fadhil Ikhsanta's Personal on 30/09/26.
//

import Foundation

struct ProductDetailDTO: Decodable {
	let id: Int
	let title: String
	let category: String
	let price: Double
	let description: String
	let images: [String]
	
	func toDomain() -> ProductDetail {
		ProductDetail(
			id: id,
			title: title,
			category: category,
			price: price,
			description: description,
			imageURLs: images.compactMap(URL.init(string:))
		)
	}
}
