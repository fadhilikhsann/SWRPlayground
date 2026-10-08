//
//  MockURLProtocol.swift
//  SWRPlayground
//
//  Created by Fadhil Ikhsanta's Personal on 06/10/26.
//


import Foundation
@testable import SWRPlayground

class MockURLProtocol: URLProtocol {
    static var requestHandlers: [URL: (URLRequest) throws -> (HTTPURLResponse, Data)] = [:]
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        guard let url = request.url, let handler = MockURLProtocol.requestHandlers[url] else {
            client?.urlProtocol(
                self,
                didFailWithError: NSError(
                    domain: "MockURLProtocol",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "No handler found for request."]
                )
            )
            return
        }
        
        do {
            let (response, data) = try handler(request)
            
            // Send the response back to the client
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            
            // Send the data back
            client?.urlProtocol(self, didLoad: data)
            
            // Finish loading
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
    
    override func stopLoading() {
        // Required override, usually left empty
    }
}
