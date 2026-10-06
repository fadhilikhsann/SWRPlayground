//
//  ProductAPIClientTests.swift
//  SWRPlaygroundTests
//
//  Created by Fadhil Ikhsanta's Personal on 06/10/26.
//

import XCTest
@testable import SWRPlayground

final class ProductAPIClientTests: XCTestCase {
    private var sut: DefaultProductAPIClient!
    private var session: URLSession!

    override func setUpWithError() throws {
        try super.setUpWithError()
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        session = URLSession(configuration: configuration)
        sut = DefaultProductAPIClient(session: session)
        MockURLProtocol.requestHandlers = [:]
    }

    override func tearDownWithError() throws {
        sut = nil
        session = nil
        MockURLProtocol.requestHandlers = [:]
        try super.tearDownWithError()
    }
    
    // MARK: Protocol Conformance Tests
    func testConformsToProductRepository() {
        XCTAssertTrue((sut as Any) is ProductAPIClient)
    }

    // MARK: fetchProductList Tests
    func testFetchProductList_whenGivenLimit20AndSkip0_returnsFirst20ProductResponseDTOs() async throws {
        // Given
        let request = PageRequest(limit: 20, skip: 0)
        let expectedURL = try XCTUnwrap(URL(string: "https://www.dummyjson.com/products?limit=20&skip=0&select=title,category,price,thumbnail"))
        let jsonResultData = try loadJSONData(filename: "ProductList.01-20")

        var capturedRequest: URLRequest?
        MockURLProtocol.requestHandlers[expectedURL] = { request in
            capturedRequest = request
            let response = HTTPURLResponse(
                url: expectedURL,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, jsonResultData)
        }

        // When
        let result = try await sut.fetchProductList(request: request)

        // Then
        XCTAssertNotNil(capturedRequest)
        XCTAssertEqual(capturedRequest?.url, expectedURL)
        XCTAssertEqual(result.limit, 20)
        XCTAssertEqual(result.skip, 0)
        XCTAssertEqual(result.products.count, 20)

        let firstProduct = try XCTUnwrap(result.products.first)
        XCTAssertEqual(firstProduct.id, 1)
        XCTAssertEqual(firstProduct.title, "Essence Mascara Lash Princess")
        XCTAssertEqual(firstProduct.category, "beauty")
        XCTAssertEqual(firstProduct.price, 9.99)
        XCTAssertEqual(firstProduct.thumbnail, "https://cdn.dummyjson.com/product-images/beauty/essence-mascara-lash-princess/thumbnail.webp")
    }

    func testFetchProductList_whenGivenLimit20AndSkip20_returnsSecond20ProductResponseDTOs() async throws {
        // Given
        let request = PageRequest(limit: 20, skip: 20)
        let expectedURL = try XCTUnwrap(URL(string: "https://www.dummyjson.com/products?limit=20&skip=20&select=title,category,price,thumbnail"))
        let jsonResultData = try loadJSONData(filename: "ProductList.21-40")

        MockURLProtocol.requestHandlers[expectedURL] = { request in
            let response = HTTPURLResponse(
                url: expectedURL,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, jsonResultData)
        }

        // When
        let result = try await sut.fetchProductList(request: request)

        // Then
        XCTAssertEqual(result.limit, 20)
        XCTAssertEqual(result.skip, 20)
        XCTAssertEqual(result.products.count, 20)
    }

    func testFetchProductList_whenAPIClientReturnsStatusCodeError_throwsAPIClientErrorHTTPStatus() async throws {
        // Given
        let request = PageRequest(limit: 20, skip: 0)
        let expectedURL = try XCTUnwrap(URL(string: "https://www.dummyjson.com/products?limit=20&skip=0&select=title,category,price,thumbnail"))

        MockURLProtocol.requestHandlers[expectedURL] = { request in
            let response = HTTPURLResponse(
                url: expectedURL,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        // When / Then
        do {
            _ = try await sut.fetchProductList(request: request)
            XCTFail("Expected fetchProductList to throw APIClientError.httpStatus(500)")
        } catch let error as APIClientError {
            if case let .httpStatus(statusCode) = error {
                XCTAssertEqual(statusCode, 500)
            } else {
                XCTFail("Expected .httpStatus(500), got \(error)")
            }
        } catch {
            XCTFail("Expected APIClientError, got \(error)")
        }
    }

    func testFetchProductList_whenAPIClientReturnsInvalidJSON_throwsDecodingError() async throws {
        // Given
        let request = PageRequest(limit: 20, skip: 0)
        let expectedURL = try XCTUnwrap(URL(string: "https://www.dummyjson.com/products?limit=20&skip=0&select=title,category,price,thumbnail"))
        let corruptData = Data("invalid json".utf8)

        MockURLProtocol.requestHandlers[expectedURL] = { request in
            let response = HTTPURLResponse(
                url: expectedURL,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, corruptData)
        }

        // When / Then
        do {
            _ = try await sut.fetchProductList(request: request)
            XCTFail("Expected decoding error to be thrown")
        } catch is DecodingError {
            // Expected
        } catch {
            XCTFail("Expected DecodingError, got \(error)")
        }
    }

    func testFetchProductList_whenAPIClientReturnsURLError_throwsURLError() async throws {
        // Given
        let request = PageRequest(limit: 20, skip: 0)
        let expectedURL = try XCTUnwrap(URL(string: "https://www.dummyjson.com/products?limit=20&skip=0&select=title,category,price,thumbnail"))

        MockURLProtocol.requestHandlers[expectedURL] = { _ in
            throw URLError(.notConnectedToInternet)
        }

        // When / Then
        do {
            _ = try await sut.fetchProductList(request: request)
            XCTFail("Expected network error to be thrown")
        } catch let error as URLError {
            XCTAssertEqual(error.code, .notConnectedToInternet)
        } catch {
            XCTFail("Expected URLError, got \(error)")
        }
    }

    // MARK: fetchProductDetail Tests
    func testFetchProductDetail_whenGivenId1_returnsProductDetailDTOWithId1() async throws {
        // Given
        let productId = 1
        let expectedURL = try XCTUnwrap(URL(string: "https://www.dummyjson.com/products/1?select=title,category,price,description,images"))
        let jsonResultData = try loadJSONData(filename: "ProductDetail.1")

        var capturedRequest: URLRequest?
        MockURLProtocol.requestHandlers[expectedURL] = { request in
            capturedRequest = request
            let response = HTTPURLResponse(
                url: expectedURL,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, jsonResultData)
        }

        // When
        let result = try await sut.fetchProductDetail(id: productId)

        // Then
        XCTAssertNotNil(capturedRequest)
        XCTAssertEqual(capturedRequest?.url, expectedURL)
        XCTAssertEqual(result.id, 1)
        XCTAssertEqual(result.title, "Essence Mascara Lash Princess")
        XCTAssertEqual(result.category, "beauty")
        XCTAssertEqual(result.price, 9.99)
        XCTAssertFalse(result.description.isEmpty)
        XCTAssertFalse(result.images.isEmpty)
    }

    func testFetchProductDetail_whenGivenId2_returnsProductDetailDTOWithId2() async throws {
        // Given
        let productId = 2
        let expectedURL = try XCTUnwrap(URL(string: "https://www.dummyjson.com/products/2?select=title,category,price,description,images"))
        let jsonResultData = try loadJSONData(filename: "ProductDetail.2")

        MockURLProtocol.requestHandlers[expectedURL] = { request in
            let response = HTTPURLResponse(
                url: expectedURL,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, jsonResultData)
        }

        // When
        let result = try await sut.fetchProductDetail(id: productId)

        // Then
        XCTAssertEqual(result.id, 2)
    }

    func testFetchProductDetail_whenAPIClientReturnsStatusCodeError_throwsAPIClientErrorHTTPStatus() async throws {
        // Given
        let productId = 999
        let expectedURL = try XCTUnwrap(URL(string: "https://www.dummyjson.com/products/999?select=title,category,price,description,images"))

        MockURLProtocol.requestHandlers[expectedURL] = { request in
            let response = HTTPURLResponse(
                url: expectedURL,
                statusCode: 404,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        // When / Then
        do {
            _ = try await sut.fetchProductDetail(id: productId)
            XCTFail("Expected fetchProductDetail to throw APIClientError.httpStatus(404)")
        } catch let error as APIClientError {
            if case let .httpStatus(statusCode) = error {
                XCTAssertEqual(statusCode, 404)
            } else {
                XCTFail("Expected .httpStatus(404), got \(error)")
            }
        } catch {
            XCTFail("Expected APIClientError, got \(error)")
        }
    }

    func testFetchProductDetail_whenAPIClientReturnsInvalidJSON_throwsDecodingError() async throws {
        // Given
        let productId = 1
        let expectedURL = try XCTUnwrap(URL(string: "https://www.dummyjson.com/products/1?select=title,category,price,description,images"))
        let corruptData = Data("invalid json".utf8)

        MockURLProtocol.requestHandlers[expectedURL] = { request in
            let response = HTTPURLResponse(
                url: expectedURL,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, corruptData)
        }

        // When / Then
        do {
            _ = try await sut.fetchProductDetail(id: productId)
            XCTFail("Expected decoding error to be thrown")
        } catch is DecodingError {
            // Expected
        } catch {
            XCTFail("Expected DecodingError, got \(error)")
        }
    }

    func testFetchProductDetail_whenAPIClientReturnsURLError_throwsURLError() async throws {
        // Given
        let productId = 1
        let expectedURL = try XCTUnwrap(URL(string: "https://www.dummyjson.com/products/1?select=title,category,price,description,images"))

        MockURLProtocol.requestHandlers[expectedURL] = { _ in
            throw URLError(.timedOut)
        }

        // When / Then
        do {
            _ = try await sut.fetchProductDetail(id: productId)
            XCTFail("Expected network error to be thrown")
        } catch let error as URLError {
            XCTAssertEqual(error.code, .timedOut)
        } catch {
            XCTFail("Expected URLError, got \(error)")
        }
    }
}

// MARK: Helper Methods
extension ProductAPIClientTests {
    private func loadJSONData(filename: String) throws -> Data {
        let bundle = Bundle(for: ProductAPIClientTests.self)
        if let url = bundle.url(forResource: filename, withExtension: "json") {
            return try Data(contentsOf: url)
        }
        if let url = bundle.url(forResource: filename, withExtension: nil) {
            return try Data(contentsOf: url)
        }
        XCTFail("Could not locate JSON file: \(filename)")
        throw APIClientError.invalidURL
    }
}
