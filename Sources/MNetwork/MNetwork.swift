
import Foundation
import Combine
/// Network class is singleton instance wich adds open api to ensure the all third part calls wrapped to create rerquest from here
@available(OSX 10.15, *)
class MNetWork {

    private init() {}

    // private instance
    private var networkingLayer: APINetwork  =  APINetwork(session: .shared)

    public static let shared = MNetWork()

    /// if you want to make a mock session as of now you cam add it here
    /// then onwords all the calls will use the same mock session , until updated
    public static func addCustomSession(_ session: URLSession) {
        self.shared.networkingLayer =  APINetwork(session: session)
    }

    /// If you have to use a body from a class data
    /// or struct use this method
    
    public static func request<ResponseDecodable: Decodable,
                        RequestEncodable: Encodable>(
        _ url: String,
        path: String = "",
        method: HTTPMethod = .get,
        parameters: [String: Any]? = nil,
        body: RequestEncodable? = nil,
        encoding: NetworkEncodingType = .json,
        headers: [String: Any]? = nil,
        responseType: ResponseDecodable.Type) -> AnyPublisher<ResponseDecodable, Error> {
        // create a requestBody with the given object
        // if the object exists
        var requestBody: NetworkBody?
        if let body = body {
            requestBody = try? NetworkBody(object: body, encoding: encoding )
        }
        // invoke the request with request body
        return self.request(url, path: path,
                       method: method,
                       parameters: parameters,
                       requestBody: requestBody,
                       headers: headers,
                       responseType: responseType)

    }
    // If you have to use a body from a diction0ry
    // use the this method
    public static  func request<ResponseDecodable: Decodable>(
        _ url: String,
        path: String = "",
        method: HTTPMethod = .get,
        parameters: [String: Any]? = nil,
        body: [String: Any]?,
        encoding: NetworkEncodingType = .json,
        headers: [String: Any]? = nil,
        responseType: ResponseDecodable.Type
        ) -> AnyPublisher<ResponseDecodable, Error> {

        // create a requestBody with the given dictionary
        // if the dictionary exists
        var requestBody: NetworkBody?
        if let body = body {
            requestBody = try? NetworkBody(dictionary: body, encoding: encoding )
        }
        // invoke the request with request body
        return self.request(url, path: path,
                       method: method,
                       parameters: parameters,
                       requestBody: requestBody,
                       headers: headers,
                       responseType: responseType)

    }

    // If you have to use a custom network body
    // use the this method
    public static  func request<ResponseDecodable: Decodable>(
        _ url: String,
        path: String = "",
        method: HTTPMethod = .get,
        parameters: [String: Any]? = nil,
        requestBody: NetworkBody? = nil,
        headers: [String: Any]? = nil,
        responseType: ResponseDecodable.Type
        ) -> AnyPublisher<ResponseDecodable, Error> {

        // Create an APi request out network client can use
        let request  = APIRequest(url: url,
                                  path: path,
                                  method: method,
                                  parameters: parameters,
                                  body: requestBody)

        // use the shared networklayer to call the api
        return  self.shared.networkingLayer.send(request: request,
                                    responseType: responseType)
            .eraseToAnyPublisher()

    }
}
