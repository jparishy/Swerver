//
//  Server.swift
//  Swerver
//
//  Created by Julius Parishy on 12/4/15.
//  Copyright © 2015 Julius Parishy. All rights reserved.
//

import Foundation

let SwerverName = "Swerver"
let SwerverVersion = "1.0"

class HTTPServer<HTTP: HTTPVersion> : TCPServer {
    let port: Int
    let router: Router
    
    init(port: Int, router: Router) {
        self.port = port
        self.router = router
        
        super.init(bindAddress: "0.0.0.0", port: port)
    }
    
    private func handle(rawRequest: NSData, HTTP: HTTPVersion) -> Response {
        if let request = HTTP.request() {
            if let route = router.route(request.path) {
                do {
                    return try route.routeProvider.apply(request)
                } catch {
                    return BuiltInResponse(.InternalServerError)
                }
            } else {
                return BuiltInResponse(.NotFound)
            }
        }

        return BuiltInResponse(.InternalServerError)
    }
    
    override func processRequest(request: NSData?) -> NSData? {
        if let data = request {
            let HTTP = GetHTTP(data)
            let response = handle(data, HTTP: HTTP)
            return responseDataFromResponse(response, HTTP: HTTP)
        }
        
        return nil
    }
    
    private func responseDataFromResponse(response: Response, HTTP: HTTPVersion) -> NSData {
	let dataString = response.responseData?.dataString
	let data: [UInt8]? = (dataString != nil) ? [UInt8](dataString!.utf8) : nil
        return HTTP.response(response.statusCode, headers: response.headers, data: data) 
    }
}
