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

public typealias Headers = [String:String]

public enum StatusCode {
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

public enum InternalServerError : ErrorType {
    case Generic
}

public enum UserError : ErrorType {
    case Unimplemented
}

//typealias Response = (statusCode: StatusCode, headers: Headers, responseData: ResponseData?)

public struct Session {
    static let CookieName = "_swerver_session"
    internal var dictionary: [String:Any] = [:]
    
    internal init?(JSONData: NSData) {
        do {
            let JSON = try NSJSONSerialization.JSONObjectWithData(JSONData, options: NSJSONReadingOptions(rawValue: 0))
            dictionary = JSON as! [String : Any]
        } catch {
            return nil
        }
    }
    
    public init() { }
    
    public mutating func update(key: String, _ value: Any?) {
        dictionary[key] = value ?? NSNull()
    }
    
    mutating func merge(otherSession session: Session) {
        for (k,v) in session.dictionary {
            if v is NSNull {
                dictionary.removeValueForKey(k)
            } else {
                dictionary[k] = v
            }
        }
    }
    
    public subscript(key: String) -> Any? {
        return dictionary[key]
    }
}

public struct Request {
    public let method: HTTPMethod
    public let path: String
    public let headers: Headers
    public let requestBody: NSData?

    public init(method: HTTPMethod, path: String, headers: Headers, requestBody: NSData?) {
        self.method = method
        self.path = path
        self.headers = headers
        self.requestBody = requestBody
    }
}

public class Response {
    let statusCode: StatusCode
    let headers: Headers
    let responseData: ResponseData?
    
    init(_ statusCode: StatusCode, headers: Headers = [:], responseData: ResponseData? = nil) {
        self.statusCode = statusCode
        self.headers = headers
        self.responseData = responseData
    }
}

extension Request : CustomStringConvertible {
    public var description: String {
        return "<Reqest: method=\(method); path=\(path); numberOfHeaders=\(headers.count); requestLength=\(requestBody?.length ?? 0)>"
    }
}

public extension NSString {
    public static func fromData(data: [UInt8]) -> NSString? {
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

public class ResponseData {
    public let data: NSData
    
    public init(_ string: String) {
        let bytes = string.swerver_cStringUsingEncoding(NSUTF8StringEncoding)
        data = NSData(bytes: bytes, length: bytes.count)
    }
    
    public init(_ data: NSData) {
        self.data = data
    }
    
    public var stringView: String? {
        let bytes = data.bytes
        return NSString(bytes: bytes, length: data.length, encoding: NSUTF8StringEncoding)?.bridge()
    }
    
    public var description: String {
        if let stringView = stringView {
            return "<Data: \"\(stringView)\">"
        } else {
            return "<Data: \(data)>"
        }
    }
    
    public static func Data(data: NSData) -> ResponseData? {
        if let str = NSString(bytes: data.bytes, length: data.length, encoding: NSUTF8StringEncoding)?.bridge() {
            return ResponseData(str)
        } else {
            return nil
        }
    }
    
    public static func PublicFileExists(filename: String, publicDirectory dir: String) -> Bool {
        let filename = "\(dir)/\(filename)"
        return (access(filename, F_OK) >= 0)
    }
    
    public class func PublicFile(filename: String, publicDirectory dir: String) throws -> (ResponseData?, Headers) {
        let data = try NSData(contentsOfFile: "\(dir)/\(filename)", options: NSDataReadingOptions(rawValue: 0))
        
        var headers: Headers = [:]
        if let ext = filename.bridge().swerver_componentsSeparatedByString(".").last?.lowercaseString {
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

public func BuiltInResponse(code: StatusCode, publicDirectory dir: String) -> Response {
    switch code {
        case .NotFound:
            do {
                let (file, headers) = try ResponseData.PublicFile("404.html", publicDirectory: dir)
                return Response(code, headers: headers, responseData: file)
            } catch {
                print("WARNING: 500.html Not Found.")
                return Response(code)
            }
        
        case .InternalServerError:
            do {
                let (file, headers) = try ResponseData.PublicFile("500.html", publicDirectory: dir)
                return Response(code, headers: headers, responseData: file)
            } catch {
                print("WARNING: 500.html Not Found.")
                return Response(code)
            }
        
        default:
            return Response(code)
    }
}

public struct Ok {
    public static func JSON(model: Model) throws -> Response {
        let data = try NSJSONSerialization.swerver_dataWithJSONObject(try model.JSON(), options: NSJSONWritingOptions(rawValue: 0))
        return Response(.Ok, headers: ["Content-Type" : "application/json"], responseData: ResponseData(data))
    }
    
    public static func JSON(models: [Model]) throws -> Response {
        let data = try NSJSONSerialization.swerver_dataWithJSONObject(try models.JSON(), options: NSJSONWritingOptions(rawValue: 0))
        return Response(.Ok, headers: ["Content-Type" : "application/json"], responseData: ResponseData(data))
    }
    
    public static func JSON(dictionary: NSDictionary) throws -> Response {
        let data = try NSJSONSerialization.swerver_dataWithJSONObject(dictionary, options: NSJSONWritingOptions(rawValue: 0))
        return Response(.Ok, headers: ["Content-Type" : "application/json"], responseData: ResponseData(data))
    }
    
    public static func JSON(array: NSArray) throws -> Response {
        let data = try NSJSONSerialization.swerver_dataWithJSONObject(array, options: NSJSONWritingOptions(rawValue: 0))
        return Response(.Ok, headers: ["Content-Type" : "application/json"], responseData: ResponseData(data))
    }
}

public enum ContentType {
    case Unspecified
    case JSON
    case URLEncoded
    case HTML
}

public func RespondToFormat(request: Request, work: (ContentType) throws -> Response) throws -> Response? {
    if let format = request.headers["Accept"] where format == "text/html" {
        return try work(.HTML)
    } else {
        return try work(.JSON)
    }
}

public func Respond(request: Request, _ allowedContentTypes: [ContentType] = [], work: (responseContentType: ContentType) throws -> Response?) throws -> Response {
    
    let requestType: ContentType
    if let format = request.headers["Content-Type"] where format.bridge().rangeOfString("application/json").location != NSNotFound {
        requestType = .JSON
    } else {
        requestType = .Unspecified
    }
    
    if requestType != .Unspecified && allowedContentTypes.contains(requestType) == false {
        return Response(.InvalidRequest)
    }
    
    let responseType: ContentType
    if let format = request.headers["Accept"] where format.bridge().rangeOfString("application/json").location != NSNotFound {
        responseType = .JSON
    } else {
        responseType = .HTML
    }
    
    if let response =  try work(responseContentType: responseType) {
        return response
    } else {
        return Response(.InvalidRequest)
    }
}

public protocol RouteProvider {
    func apply(request: Request) throws -> Response
}

private class RedirectRouteProvider : RouteProvider {
    let to: String
    init(to: String) {
        self.to = to
    }
    
    func apply(request: Request) throws -> Response {
        return Response(.MovedPermanently(to: to))
    }
}

public func Redirect(to: String) -> RouteProvider {
    return RedirectRouteProvider(to: to)
}

public class Route {
    public let routeProvider: RouteProvider
    
    public typealias MatchFunction = ((Route, Request) -> (Bool))
    public let matchFunction: MatchFunction?
    
    public init(routeProvider: RouteProvider, matchFunction: MatchFunction) {
        self.routeProvider = routeProvider
        self.matchFunction = matchFunction
    }

    public func matches(request: Request) -> Bool {
        return matchFunction?(self, request) ?? false
    }
}

public class PathRoute : Route {
    public let path: String
    
    public init(path: String, routeProvider: RouteProvider) {
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
    
    public class func root(to: String) -> Route {
        return PathRoute(path: "/", routeProvider: Redirect(to))
    }
}

public class PublicFiles : Route {
    
    public let prefix: String
    public let publicDirectory: String
    
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
                return Response(.Ok, headers: headers, responseData: file)
            } catch {
                return BuiltInResponse(.NotFound, publicDirectory: self.publicDirectory)
            }
        }
    }
    
    public init(directory dir: String, prefix: String = "" /* Root Level of URL */) {
    
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

public struct Router {
    public let routes: [Route]
    
    public init(_ routes: [Route]) {
        self.routes = routes
    }
    
    public func route(request: Request) -> Route? {
        let route = routes.filter { $0.matches(request) }.first
        if let route = route {
            return route
        } else {
            return nil
        }
    }
}
