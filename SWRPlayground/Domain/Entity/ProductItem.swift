//
//  ProductItem.swift
//  SWRPlayground
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


