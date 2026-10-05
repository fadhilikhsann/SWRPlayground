//
//  ProductResponseDTO.swift
//  Product Catalog v3
//
//  Created by Fadhil Ikhsanta's Personal on 25/09/26.
//

struct ProductResponseDTO: Decodable {
    let products: [ProductItemDTO]
    let total: Int
    let skip: Int
    let limit: Int

    func toDomain() -> ProductItemsByPage {
		ProductItemsByPage(
            products: products.map { $0.toDomain() },
            total: total,
            skip: skip,
            limit: limit
        )
    }
}
