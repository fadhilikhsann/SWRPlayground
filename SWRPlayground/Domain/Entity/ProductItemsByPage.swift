//
//  ProductItemsByPage.swift
//  Product Catalog v3
//
//  Created by Fadhil Ikhsanta's Personal on 25/09/26.
//

struct ProductItemsByPage: Equatable {
    let products: [ProductItem]
    let total: Int
    let skip: Int
    let limit: Int
}
