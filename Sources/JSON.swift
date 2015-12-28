//
//  JSON.swift
//  Swerver
//
//  Created by Julius Parishy on 12/12/15.
//  Copyright © 2015 Julius Parishy. All rights reserved.
//

import Foundation

#if os(Linux)
public typealias NSErrorPointer = UnsafeMutablePointer<NSError>
#endif

public enum JSONError : ErrorType {
    case Unimplemented
    case InvalidInput
    case UnexpectedToken(message: String, location: Int)
}

public protocol JSONEncodable { }

extension Int : JSONEncodable {}
extension Double : JSONEncodable {}
extension Float : JSONEncodable {}
extension Bool : JSONEncodable {}
extension String : JSONEncodable {}
extension Dictionary : JSONEncodable {}
extension Array : JSONEncodable {}
extension NSNull : JSONEncodable {}

public extension NSJSONSerialization {

    public class func swerver_dataWithJSONObject(obj: [JSONEncodable], options opt: NSJSONWritingOptions) throws -> NSData {
        return try _impl_swerver_dataWithJSONObject(obj, options: opt)
    }

    public class func swerver_dataWithJSONObject(obj: [String:JSONEncodable], options opt: NSJSONWritingOptions) throws -> NSData {
        return try _impl_swerver_dataWithJSONObject(obj, options: opt)
    }

    public class func swerver_dataWithJSONObject<T : JSONEncodable>(obj: [T], options opt: NSJSONWritingOptions) throws -> NSData {
        return try _impl_swerver_dataWithJSONObject(obj, options: opt)
    }

    public class func swerver_dataWithJSONObject<T : JSONEncodable>(obj: [String:T], options opt: NSJSONWritingOptions) throws -> NSData {
        return try _impl_swerver_dataWithJSONObject(obj, options: opt)
    }
}
