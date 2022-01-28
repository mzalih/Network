//
//  APINetwork.swift
//
//  Created by Muhammed salih T A on 28/01/22.
//

import Foundation
import Combine

@available(OSX 10.15, *)
@available(iOS 13.0, *)
public class APINetwork {
    
    public init(session: URLSession = URLSession.shared) {
        self.session = session
    }
    private var session: URLSession
    
    public func send<C: Decodable>(request:APIRequest, responseType: C.Type) -> AnyPublisher<C,Error> {
        guard let urlRequest = request.buildURLRequest() else {
            fatalError()
        }

        return session.dataTaskPublisher(for: urlRequest)
            .tryMap({ data, response -> C in

                guard let apiResponse = response as? HTTPURLResponse else {
                    throw APIError(message: "Invalid response", data: nil, statusCode: nil)
                }

                guard (200..<299).contains(apiResponse.statusCode) else {
                    throw APIError(message: apiResponse.description,
                                   data: data,
                                   statusCode: apiResponse.statusCode)
                }

                do {
                    let value = try JSONDecoder().decode(C.self, from: data)
                    return value
                } catch {
                    throw APIError(message: "Parsing Error", data: data)
                }
            })
            .mapError { $0 }
            .eraseToAnyPublisher()
    }
}
public struct APIRequest {

    var baseURL: URL? // base url for call
    var path: String  // path after url
    var method: HTTPMethod // normal http methos
    var parameters: [String: Any]? // query parameters
    var headers: [String: Any]? // headers if needed
    var body: NetworkBody? // Body of the request

    init( url: String, path: String, method: HTTPMethod = .get, parameters: [String: Any]? = nil, headers: [String: Any]? = nil, body: NetworkBody? = nil) {
        self.baseURL = url.url
        self.path = path
        self.method = method
        self.parameters = parameters
        self.headers = headers
        self.body = body
    }
}
// MARK: Helpers
extension APIRequest {
    // this is to create URLRequest and used in networkLayer
    func buildURLRequest() -> URLRequest? {
        guard let baseURL = baseURL else {
            return nil
        }
        var urlRequest = URLRequest(url: baseURL)
        addPath(path, to: &urlRequest)
        addMethod(method, to: &urlRequest)
        addQueryParameters(parameters, to: &urlRequest)
        addHeaders(headers, to: &urlRequest)
        addRequestBody(body, to: &urlRequest)

        return urlRequest
    }
    // Convert the url to the proper url with path ans base
    var url: URL? {
        guard let baseURL = baseURL else {
            return nil
        }
        guard !path.isEmpty else {
            return baseURL
        }
        return baseURL.appendingPathComponent(path)
    }

}

// MARK: - Private Helpers
private extension APIRequest {

    // updating URLRequest with path
    func addPath(_ path: String, to request: inout URLRequest) {
        guard !path.isEmpty else {
            return
        }

        let url = request.url?.appendingPathComponent(path)
        request.url = url
    }

    // updating URLRequest with method
    func addMethod(_ method: HTTPMethod, to request: inout URLRequest) {
        request.httpMethod = method.name
    }

    // updating URLRequest with parameters
    func addQueryParameters(_ parameters: [String: Any]?, to request: inout URLRequest) {
        guard let parameters = parameters,
              let url = request.url else {
            return
        }

        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)

        let queryItems = parameters.map { URLQueryItem(name: $0.key, value: String(describing: $0.value)) }
        components?.queryItems = queryItems

        request.url = components?.url
    }

    // updating URLRequest with headeres
    func addHeaders(_ headers: [String: Any]?, to request: inout URLRequest) {
        guard let headers = headers else {
            return
        }

        headers.forEach { request.setValue(String(describing: $0.value), forHTTPHeaderField: $0.key) }
    }

    // updating URLRequest with Body
    func addRequestBody(_ body: NetworkBody?, to request: inout URLRequest) {
        guard let body = body else {
            return
        }
        switch body.encoding {
        case .json:
            request.setValue(body.encoding.contentTypeValue, forHTTPHeaderField: "Content-Type")
            request.httpBody = body.data
        }
    }
}

public enum HTTPMethod: String {
    case get
    case post
    case put
    case delete
}
extension HTTPMethod {
    var name: String {
        return rawValue.uppercased()
    }
}

/// This Netywork Body class help the user to handle the APi in a dictionary  or Encodable
public struct NetworkBody {

    let data: Data // the data to be send on API Request
    let encoding: NetworkEncodingType // type of encoding

    // Initialise with data itself
    public init(data: Data, encoding: NetworkEncodingType = .json) {
        self.data = data
        self.encoding = encoding
    }

    // if we have a dictionary data it will convert to the Data and initialise
    public init(dictionary: [String: Any], encoding: NetworkEncodingType = .json) throws {

        var data: Data
        switch encoding {
        case .json:
            data = try JSONSerialization.data(withJSONObject: dictionary, options: [])
        }
        self.init(data: data, encoding: encoding)
    }

    // if we have a Encodable it will convert to the Data and initialise
    public init<E: Encodable>(object: E, encoding: NetworkEncodingType = .json) throws {
        let data = try JSONEncoder().encode(object)
        self.init(data: data, encoding: encoding)
    }
}

extension String {
    var url: URL?{
        if let url = URL(string: self){
            return url
        }
        return nil
    }
}
public enum NetworkEncodingType {
    case json
}

extension NetworkEncodingType {
    var contentTypeValue: String {
        switch self {
            case .json:
                return "application/json"
        }
    }
}

public struct APIError: Error, LocalizedError {
    public let message: String
    public var data: Data?
    public var statusCode: Int?
    public var errorDescription: String? {
        return message
    }
    public func errorResponse<T: Decodable>(for type: T.Type? = nil) -> T? {
        guard let data = self.data else {
            return nil
        }
        do {
            let errorResponse = try JSONDecoder().decode(T.self, from: data)
            return errorResponse
        } catch {
            return nil
        }
    }
}
