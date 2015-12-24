//
//  Server.swift
//  Swerver
//
//  Created by Julius Parishy on 12/4/15.
//  Copyright © 2015 Julius Parishy. All rights reserved.
//

import Foundation

public let SwerverName = "Swerver"
public let SwerverVersion = "1.0"

public enum HTTPMethod : String {
    case GET    = "GET"
    case POST   = "POST"
    case PUT    = "PUT"
    case DELETE = "DELETE"
    case HEAD   = "HEAD"
    
    static func fromString(str: String) -> HTTPMethod? {
        return HTTPMethod(rawValue: str.uppercaseString)
    }
}

public class HTTPServer<HTTP: HTTPVersion> : TCPServer {
    
    public let port: Int
    public let router: Router
    
    public let publicDirectory: String = "./Public"
    
    public init(port: Int, router: Router) {
        self.port = port
        self.router = router
        
        super.init(bindAddress: "0.0.0.0", port: port)
    }
    
    private func handle(rawRequest: NSData, HTTP: HTTPVersion) -> Response {
        if let request = HTTP.request() {
            if let route = router.route(request) {
                do {
                    return try route.routeProvider.apply(request)
                } catch {
                    return BuiltInResponse(.InternalServerError, publicDirectory: self.publicDirectory)
                }
            } else {
                return BuiltInResponse(.NotFound, publicDirectory: self.publicDirectory)
            }
        }

        return BuiltInResponse(.InternalServerError, publicDirectory: self.publicDirectory)
    }
    
    override func processRequest(request: NSData?) -> NSData? {
        if let data = request {
            let HTTP = GetHTTP(data)
            
            let response = handle(data, HTTP: HTTP)
            let data = responseDataFromResponse(response, HTTP: HTTP)
            
            if let request = HTTP.request() {
                print("\(response.statusCode.statusCodeString) - \(request.method) \(request.path) with response of \(data.length) bytes")
            }
            
            return data
        }
        
        return nil
    }
    
    private func responseDataFromResponse(response: Response, HTTP: HTTPVersion) -> NSData {
        return HTTP.response(response.statusCode, headers: response.headers, data: response.responseData?.data)
    }
}
