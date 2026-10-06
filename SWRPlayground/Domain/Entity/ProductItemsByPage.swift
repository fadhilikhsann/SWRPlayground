//
//  ProductItemsByPage.swift
//  SWRPlayground
//
//  Created by Fadhil Ikhsanta's Personal on 25/09/26.
//

struct ProductItemsByPage: Equatable {
    let products: [ProductItem]
    let total: Int
    let skip: Int
    let limit: Int
}
