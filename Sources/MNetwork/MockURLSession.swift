//
//  MockURLSession.swift
//
//  Created by Muhammed salih T A on 29/01/22.
//

import Foundation

public class URLProtocolMock: URLProtocol {
    /// Dictionary maps URLs to tuples of error, data, and response
    static var mockURLs = [URL?: (error: Error?, data: Data?, response: HTTPURLResponse?)]()

    public override class func canInit(with request: URLRequest) -> Bool {
        // Handle all types of requests
        return true
    }

    public override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        // Required to be implemented here. Just return what is passed
        return request
    }

    public override func startLoading() {
        if let url = request.url {
            if let (error, data, response) = URLProtocolMock.mockURLs[url] {
                
                // We have a mock response specified so return it.
                if let responseStrong = response {
                    self.client?.urlProtocol(self, didReceive: responseStrong, cacheStoragePolicy: .notAllowed)
                }
                
                // We have mocked data specified so return it.
                if let dataStrong = data {
                    self.client?.urlProtocol(self, didLoad: dataStrong)
                }
                
                // We have a mocked error so return it.
                if let errorStrong = error {
                    self.client?.urlProtocol(self, didFailWithError: errorStrong)
                }
            }
        }

        // Send the signal that we are done returning our mock response
        self.client?.urlProtocolDidFinishLoading(self)
    }

    public override func stopLoading() {
        // Required to be implemented. Do nothing here.
    }
    
}

extension URLSession{
    
    public static func mock(mocks : [URL?: (error: Error?, data: Data?, response: HTTPURLResponse?)]) ->URLSession{
   
        URLProtocolMock.mockURLs = mocks
            let sessionConfiguration = URLSessionConfiguration.ephemeral
            sessionConfiguration.protocolClasses = [URLProtocolMock.self]
            return URLSession(configuration: sessionConfiguration)
    }
    
    public static func mockResponse(
        urlString:String,
        responseData:Data?,
        statusCode:Int = 200,
        httpVersion:String? = nil,
        headerFields: [String : String]? = nil) ->  [URL?: (error: Error?, data: Data?, response: HTTPURLResponse?)]{
        
        let response = HTTPURLResponse(url: URL(string: urlString)!, statusCode: 200, httpVersion: nil, headerFields: nil)
        let url = URL(string: urlString)
       
        return [url: (nil, responseData, response)]
    }
    
}
