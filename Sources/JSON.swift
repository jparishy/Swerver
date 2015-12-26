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

    public class func swerver_isValidJSONObject(rootObject: Any) -> Bool {

        var isValid: ((Any, Bool) -> Bool)! = nil
        isValid = {
            (obj: Any, rootObject: Bool) -> Bool in
            if let array = obj as? [Any] {
                for i in 0..<array.count {
                    let obj = array[i]
                    if !isValid(obj, false) {
                        return false
                    }
                }
            } else if let dict = obj as? [String:Any] {
                for (_,v) in dict {
                    if !isValid(v, false) {
                        return false
                    }
                }
            } else {
                if (obj is Int) || (obj is Double) || (obj is Float) {
                    return !rootObject
                } else if (obj is String) || (obj is NSNumber) || (obj is JSONBool) {
                    return !rootObject
                } else {
                    print("invalid type: \(obj) \(obj.dynamicType)")
                    return false
                }
            }
            
            return true
        }
        
        return isValid(rootObject, true)
    }
    
    
    public class func swerver_dataWithJSONObject(obj: AnyObject, options opt: NSJSONWritingOptions) throws -> NSData {
        return try _impl_swerver_dataWithJSONObject(obj, options: opt)
    }
    
    public class func swerver_JSONObjectWithData(data: NSData, options opt: NSJSONReadingOptions) throws -> AnyObject {
        return try _impl_swerver_JSONObjectWithData(data, options: opt)
    }
    
    
    public class func swerver_writeJSONObject(obj: AnyObject, toStream stream: NSOutputStream, options opt: NSJSONWritingOptions, error: NSErrorPointer) -> Int {
        return 0
    }
    
    public class func swerver_JSONObjectWithStream(stream: NSInputStream, options opt: NSJSONReadingOptions) throws -> AnyObject {
        throw JSONError.Unimplemented
    }
}
