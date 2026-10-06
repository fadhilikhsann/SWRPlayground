//
//  ProductItemDTO.swift
//  SWRPlayground
//
//  Created by Fadhil Ikhsanta's Personal on 25/09/26.
//

import Foundation

struct ProductItemDTO: Decodable {
    let id: Int
    let title: String
    let category: String
    let price: Double
    let thumbnail: String

    func toDomain() -> ProductItem {
        ProductItem(
            id: id,
            title: title,
            category: category,
            price: price,
            thumbnailURL: URL(string: thumbnail)
        )
    }
}
