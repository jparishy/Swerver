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
    case InvalidRequest
    case NotFound
    case MovedPermanently(to: String)
    case InternalServerError
    
    var integerCode: Int {
        switch self {
        case .Ok: return 200
        case .InvalidRequest: return 400
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
    
    var statusCodeString: String {
        switch integerCode {
        case 200:
            return "200 OK"
        case 301:
            return "301 Moved Permanently"
        case 400:
            return "400 Invalid Request"
        case 404:
            return "404 Not Found"
        case (500...599):
            return "\(integerCode) Internal Service Error"
        default:
            return "400 Invalid Request"
        }
    }
}

enum InternalServerError : ErrorType {
    case Generic
}

enum UserError : ErrorType {
    case Unimplemented
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
    
    static func Data(data: NSData) -> ResponseData? {
        if let str = NSString(bytes: data.bytes, length: data.length, encoding: NSUTF8StringEncoding)?.bridge() {
            return ResponseData(string: str)
        } else {
            return nil
        }
    }
    
    static func PublicFile(filename: String) throws -> ResponseData? {
        let string = try NSString(contentsOfFile: "./Public/\(filename)", encoding: NSUTF8StringEncoding)
        return ResponseData.Str(string.bridge())
    }
}

func BuiltInResponse(code: StatusCode) -> Response {
    switch code {
        case .NotFound:
            return (code, [:], ResponseData.Str("Not Found"))
        
        case .InternalServerError:
            do {
                let file = try ResponseData.PublicFile("500.html")
                return (code, [:], file)
            } catch {
                print("WARNING: 500.html Not Found.")
                return (code, [:], nil)
            }
        
        default:
            return (code, [:], nil)
    }
}

enum ResponseFormat {
    case JSON
    case HTML
}

func RespondTo(request: Request, work: (ResponseFormat) throws -> Response) throws -> Response {
    if let format = request.headers["Accept"] where format == "text/html" {
        return try work(.HTML)
    } else {
        return try work(.JSON)
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

class Route {
    let routeProvider: RouteProvider
    
    typealias MatchFunction = ((Route, Request) -> (Bool))
    let matchFunction: MatchFunction?
    
    init(routeProvider: RouteProvider, matchFunction: MatchFunction) {
        self.routeProvider = routeProvider
        self.matchFunction = matchFunction
    }

    func matches(request: Request) -> Bool {
        return matchFunction?(self, request) ?? false
    }
}

class PathRoute : Route {
    let path: String
    
    init(path: String, routeProvider: RouteProvider) {
        self.path = path
        
        let matchFunction = {
            (route: Route, request: Request) -> Bool in
            if let r = route as? PathRoute {
                return (request.path == r.path)
            } else {
                return false
            }
        }
        
        super.init(routeProvider: routeProvider, matchFunction: matchFunction)
    }
}

struct Router {
    let routes: [Route]
    
    func route(request: Request) -> Route? {
        let route = routes.filter { $0.matches(request) }.first
        if let route = route {
            return route
        } else {
            return nil
        }
    }
}
