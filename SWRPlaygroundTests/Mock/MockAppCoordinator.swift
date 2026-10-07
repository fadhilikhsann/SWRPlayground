//
//  MockAppCoordinator.swift
//  SWRPlayground
//
//  Created by Fadhil Ikhsanta's Personal on 07/10/26.
//

@testable import SWRPlayground

final class MockAppCoordinator: AppCoordinatorDelegate {
    var startCallCount = 0
    var showProductDetailScreenCallCount = 0
    var lastSelectedProductId: Int?

    func start() {
        startCallCount += 1
    }

    func showProductDetailScreen(productId: Int) {
        showProductDetailScreenCallCount += 1
        lastSelectedProductId = productId
    }
}
