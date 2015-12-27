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

public extension NSJSONSerialization {
    
    public class func swerver_dataWithJSONObject(obj: Any, options opt: NSJSONWritingOptions) throws -> NSData {
        return try _impl_swerver_dataWithJSONObject(obj, options: opt)
    }
}
