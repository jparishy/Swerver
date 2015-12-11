//
//  Router.swift
//  Swerver
//
//  Created by Julius Parishy on 12/4/15.
//  Copyright © 2015 Julius Parishy. All rights reserved.
//

import Foundation

typealias Headers = [String:String]

enum StatusCode {
    case Ok
    case NotFound
    case MovedPermanently(to: String)
    case InternalServerError
    
    var integerCode: Int {
        switch self {
        case .Ok: return 200
        case .NotFound: return 404
        case .MovedPermanently: return 301
        case .InternalServerError: return 500
        }
    }
    
    var additionalHeaders: Headers {
        switch self {
        case let .MovedPermanently(to):
            return ["Location": to]
        default:
            return [:]
        }
    }
}

enum InternalServerError : ErrorType {
    case Generic
}

typealias Response = (statusCode: StatusCode, headers: Headers, responseData: ResponseData?)

struct Request {
    let method: String
    let path: String
    let headers: Headers
    let requestBody: NSData?
}

extension Request : CustomStringConvertible {
    var description: String {
        return "<Reqest: method=\(method); path=\(path); numberOfHeaders=\(headers.count); requestLength=\(requestBody?.length ?? 0)>"
    }
}

extension NSString {
    static func fromData(data: [UInt8]) -> NSString? {
        let cString = UnsafePointer<Int8>(data)
#if os(Linux)
        let r = NSString(CString: cString, encoding: NSUTF8StringEncoding)
	print("r: \(r)")
	return r
#else
        if let str = String(CString: cString, encoding: NSUTF8StringEncoding) {
            return str as NSString
        } else {
            return nil
        }
#endif
    }
}

class ResponseData {
    let dataString: String
    
    init(string: String) {
        dataString = string
    }
    
    var description: String {
        return "<Data: \"\(dataString)\">"
    }
    
    static func Str(string: String) -> ResponseData {
        return ResponseData(string: string)
    }
}

func BuiltInResponse(code: StatusCode) -> Response {
    switch code {
        case .NotFound:
            return (code, [:], ResponseData.Str("Not Found"))
        default:
            return (code, [:], nil)
    }
}

protocol RouteProvider {
    func apply(request: Request) throws -> Response
}

private class RedirectRouteProvider : RouteProvider {
    let to: String
    init(to: String) {
        self.to = to
    }
    
    func apply(request: Request) throws -> Response {
        return (.MovedPermanently(to: to), [:], nil)
    }
}

func Redirect(to: String) -> RouteProvider {
    return RedirectRouteProvider(to: to)
}

struct Route {
    let namespace: String?
    let path: String
    let routeProvider: RouteProvider
    
    init(path: String, routeProvider: RouteProvider) {
        self.namespace = nil
        self.path = path
        self.routeProvider = routeProvider
    }
}

struct Router {
    let routes: [Route]
    
    func route(path: String) -> Route? {
        let route = routes.filter { $0.path == path }.first
        if let route = route {
            return route
        } else {
            return nil
        }
    }
}
