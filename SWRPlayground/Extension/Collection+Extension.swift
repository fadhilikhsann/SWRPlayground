//
//  Collection+Extension.swift
//  Product Catalog v3
//
//  Created by Fadhil Ikhsanta's Work on 28/09/26.
//

extension Collection {
    subscript(safe index: Index) -> Element? {
        self.indices.contains(index) ? self[index] : nil
    }
}
