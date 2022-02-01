//
//  UITestSupport.swift
//
//  Created by Muhammed salih T A on 01/02/22.
//

import Foundation

protocol AddLocalTestFile: class{
    
}

public protocol TestableAPi{
    static func mocks()-> [TestPaths]
}

public struct TestPaths{
    let url:String
    let file:String
}

extension AddLocalTestFile{
    
    func loadStub(name: String, extension: String = "json") -> URL? {
        let bundle = Bundle(for: type(of: self))

        let url = bundle.url(forResource: name, withExtension: `extension`)

        return url
    }
    
    func loadStubString(name: String, extension: String = "json") -> String? {
        return loadStub(name: name, extension: `extension`)?.absoluteString
    }

    func readLocalJsonFromBundle(forBundlePath bundlePath: URL?) -> Data? {
       do {
        if let bundlePath = bundlePath {
               let jsonData = try Data(contentsOf:bundlePath )
               return jsonData
        }
       } catch {
           print(error)
       }
       
       return nil
    }
     func readLocalJson(forName name: String) -> Data? {
        
            if let bundlePath = loadStub(name: name){
                //let jsonData = try Data(contentsOf:bundlePath )
                return readLocalJsonFromBundle(forBundlePath:bundlePath )
            }
        return nil
    }
}

extension URLSession: AddLocalTestFile {
    public static func instance(_ service:TestableAPi.Type) -> URLSession{
        if AppConfig.Testing.shouldUseLocalTestData {
            let mocks  = service.mocks()
            var allMocks = [URL?: (error: Error?, data: Data?, response: HTTPURLResponse?)]()
            for item in mocks{
                
            if let file  = AppConfig.Testing.responsePath(item: item.file ){
                let data = URLSession.shared.readLocalJsonFromBundle(forBundlePath:file.url)
            let urlString = (item.url)
                allMocks[item.url.url] = URLSession
                    .mockResponse(
                        urlString: urlString,
                        responseData: data)
            }
            }
            return URLSession
                .mock(mocks:allMocks)
           
        }
        return .shared
    }
}
