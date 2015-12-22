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

//typealias Response = (statusCode: StatusCode, headers: Headers, responseData: ResponseData?)

public struct Session {
    static let CookieName = "_swerver_session"
    internal var dictionary: [String:AnyObject] = [:]
    
    internal init?(JSONData: NSData) {
        do {
            if let JSON = try NSJSONSerialization.swerver_JSONObjectWithData(JSONData, options: NSJSONReadingOptions(rawValue: 0)) as? NSDictionary {
                dictionary = JSON.mutableCopy() as! [String:AnyObject]
            } else {
                return nil
            }
        } catch {
            return nil
        }
    }
    
    init() { }
    
    mutating func update(key: String, _ value: AnyObject?) {
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
    
    subscript(key: String) -> AnyObject? {
        return dictionary[key]
    }
}

public struct Request {
    let method: HTTPMethod
    let path: String
    let headers: Headers
    let requestBody: NSData?
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

func BuiltInResponse(code: StatusCode, publicDirectory dir: String) -> Response {
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

struct Ok {
    static func JSON(model: Model) throws -> Response {
        let data = try NSJSONSerialization.swerver_dataWithJSONObject(try model.JSON(), options: NSJSONWritingOptions(rawValue: 0))
        return Response(.Ok, headers: ["Content-Type" : "application/json"], responseData: ResponseData(data))
    }
    
    static func JSON(models: [Model]) throws -> Response {
        let data = try NSJSONSerialization.swerver_dataWithJSONObject(try models.JSON(), options: NSJSONWritingOptions(rawValue: 0))
        return Response(.Ok, headers: ["Content-Type" : "application/json"], responseData: ResponseData(data))
    }
    
    static func JSON(dictionary: NSDictionary) throws -> Response {
        let data = try NSJSONSerialization.swerver_dataWithJSONObject(dictionary, options: NSJSONWritingOptions(rawValue: 0))
        return Response(.Ok, headers: ["Content-Type" : "application/json"], responseData: ResponseData(data))
    }
    
    static func JSON(array: NSArray) throws -> Response {
        let data = try NSJSONSerialization.swerver_dataWithJSONObject(array, options: NSJSONWritingOptions(rawValue: 0))
        return Response(.Ok, headers: ["Content-Type" : "application/json"], responseData: ResponseData(data))
    }
}

enum ContentType {
    case Unspecified
    case JSON
    case URLEncoded
    case HTML
}

func RespondToFormat(request: Request, work: (ContentType) throws -> Response) throws -> Response? {
    if let format = request.headers["Accept"] where format == "text/html" {
        return try work(.HTML)
    } else {
        return try work(.JSON)
    }
}

func Respond(request: Request, _ allowedContentTypes: [ContentType] = [], work: (responseContentType: ContentType) throws -> Response?) throws -> Response {
    
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

protocol RouteProvider {
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

func Redirect(to: String) -> RouteProvider {
    return RedirectRouteProvider(to: to)
}

public class Route {
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
    
    class func root(to: String) -> Route {
        return PathRoute(path: "/", routeProvider: Redirect(to))
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
                return Response(.Ok, headers: headers, responseData: file)
            } catch {
                return BuiltInResponse(.NotFound, publicDirectory: self.publicDirectory)
            }
        }
    }
    
    init(directory dir: String, prefix: String = "" /* Root Level of URL */) {
    
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
    
    init(_ routes: [Route]) {
        self.routes = routes
    }
    
    func route(request: Request) -> Route? {
        let route = routes.filter { $0.matches(request) }.first
        if let route = route {
            return route
        } else {
            return nil
        }
    }
}
