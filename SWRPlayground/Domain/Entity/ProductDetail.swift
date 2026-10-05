//
//  ProductDetail.swift
//  Product Catalog v3
//
//  Created by Fadhil Ikhsanta's Personal on 29/09/26.
//

import Foundation

struct ProductDetail: Identifiable, Equatable {
	let id: Int
	let title: String
	let category: String
	let price: Double
	let description: String
	let imageURLs: [URL]
}
