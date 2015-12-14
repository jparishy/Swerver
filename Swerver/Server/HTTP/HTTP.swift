//
//  HTTP.swift
//  Swerver
//
//  Created by Julius Parishy on 12/5/15.
//  Copyright © 2015 Julius Parishy. All rights reserved.
//

import Foundation

func GetHTTP(rawRequest: NSData) -> HTTPVersion {
    return HTTP11(rawRequest: rawRequest)
}

protocol HTTPVersion {
    init(rawRequest: NSData)
    func request() -> Request?
    func response(statusCode: StatusCode, headers: Headers, data: NSData?) -> NSData
}
