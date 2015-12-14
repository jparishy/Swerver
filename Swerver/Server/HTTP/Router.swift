//
//  Router.swift
//  Swerver
//
//  Created by Julius Parishy on 12/4/15.
//  Copyright © 2015 Julius Parishy. All rights reserved.
//

import Foundation

#if os(Linux)
import Glibc
#endif

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
    let data: NSData
    
    init(_ string: String) {
        let bytes = string.swerver_cStringUsingEncoding(NSUTF8StringEncoding)
        data = NSData(bytes: bytes, length: bytes.count)
    }
    
    init(_ data: NSData) {
        self.data = data
    }
    
    var stringView: String? {
        let bytes = data.bytes
        return NSString(bytes: bytes, length: data.length, encoding: NSUTF8StringEncoding)?.bridge()
    }
    
    var description: String {
        if let stringView = stringView {
            return "<Data: \"\(stringView)\">"
        } else {
            return "<Data: \(data)>"
        }
    }
    
    static func Data(data: NSData) -> ResponseData? {
        if let str = NSString(bytes: data.bytes, length: data.length, encoding: NSUTF8StringEncoding)?.bridge() {
            return ResponseData(str)
        } else {
            return nil
        }
    }
    
    static func PublicFileExists(filename: String, publicDirectory dir: String) -> Bool {
        let filename = "\(dir)/\(filename)"
        return (access(filename, F_OK) >= 0)
    }
    
    class func PublicFile(filename: String, publicDirectory dir: String) throws -> (ResponseData?, Headers) {
        let data = try NSData(contentsOfFile: "\(dir)/\(filename)", options: NSDataReadingOptions(rawValue: 0))
        
        var headers: Headers = [:]
        if let ext = filename.bridge().componentsSeparatedByString(".").last?.lowercaseString {
            let contentTypes = [
            
                // Images
                "jpg"  : "image/jpg",
                "jpeg" : "image/jpg",
                "png"  : "image/png",
                "gif"  : "image/gif",
                
                // HTML
                "html" : "text/html",
                
                // CSS
                "css"  : "text/css",
                
                // JS
                "js"   : "application/js"
            ]
            
            if let contentType = contentTypes[ext] {
                headers["Content-Type"] = contentType
            }
        }
        
        
        return (ResponseData(data), headers)
    }
}

func BuiltInResponse(code: StatusCode, publicDirectory dir: String) -> Response {
    switch code {
        case .NotFound:
            do {
                let (file, headers) = try ResponseData.PublicFile("404.html", publicDirectory: dir)
                return (code, headers, file)
            } catch {
                print("WARNING: 500.html Not Found.")
                return (code, [:], nil)
            }
        
        case .InternalServerError:
            do {
                let (file, headers) = try ResponseData.PublicFile("500.html", publicDirectory: dir)
                return (code, headers, file)
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

class PublicFiles : Route {
    
    let prefix: String
    let publicDirectory: String
    
    class Provider : RouteProvider {
        let prefix: String
        let publicDirectory: String
        
        init(prefix: String, publicDirectory dir: String) {
            self.prefix = prefix
            self.publicDirectory = dir
        }
        
        func apply(request: Request) throws -> Response {
            let path: NSString
            if request.path.hasPrefix("/") {
                path = request.path.bridge().substringFromIndex(1).bridge()
            } else {
                path = request.path.bridge()
            }
            
            var restOfPath = path.substringFromIndex(self.prefix.bridge().length).bridge()
            if restOfPath.hasPrefix("/") {
                restOfPath = restOfPath.substringFromIndex(1).bridge()
            }
            
            do {
                let (file, headers) = try ResponseData.PublicFile(restOfPath.bridge(), publicDirectory: self.publicDirectory)
                return (.Ok, headers, file)
            } catch {
                return BuiltInResponse(.NotFound, publicDirectory: self.publicDirectory)
            }
        }
    }
    
    init(publicDirectory dir: String, prefix: String = "" /* Root Level of URL */) {
    
        self.publicDirectory = dir
        self.prefix = prefix
        
        let matchFunction = {
            (route: Route, request: Request) -> Bool in
            
            let path: NSString
            if request.path.hasPrefix("/") {
                path = request.path.bridge().substringFromIndex(1).bridge()
            } else {
                path = request.path.bridge()
            }
            
            if let r = route as? PublicFiles {
                let prefix = r.prefix
                if prefix == "" {
                    return ResponseData.PublicFileExists(path.bridge(), publicDirectory: r.publicDirectory)
                } else {
                    if path.hasPrefix(prefix) {
                        return ResponseData.PublicFileExists(path.bridge(), publicDirectory: r.publicDirectory)
                    } else {
                        return false
                    }
                }
            } else {
                return false
            }
        }
        
        super.init(routeProvider: Provider(prefix: prefix ?? "", publicDirectory: self.publicDirectory), matchFunction: matchFunction)
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
