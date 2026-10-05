//
//  ProductItem.swift
//  Product Catalog v3
//
//  Created by Fadhil Ikhsanta's Personal on 25/09/26.
//

import Foundation

struct ProductItem: Identifiable, Equatable {
    let id: Int
    let title: String
    let category: String
    let price: Double
    let thumbnailURL: URL?
}


