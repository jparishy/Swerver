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

enum JSONError : ErrorType {
    case Unimplemented
    case InvalidInput
    case UnexpectedToken(message: String, location: Int)
}

extension NSJSONSerialization {

    public class func swerver_isValidJSONObject(rootObject: AnyObject) -> Bool {
        var isValid: ((AnyObject, Bool) -> Bool)! = nil
        isValid = {
            (obj: AnyObject, rootObject: Bool) -> Bool in
            if let array = obj as? NSArray {
                for i in 0..<array.count {
                    let obj = array.objectAtIndex(i)
                    if !isValid(obj, false) {
                        return false
                    }
                }
            } else if let dict = obj as? NSDictionary {
                for keyAny in dict.keyEnumerator() {
                    if let key = keyAny as? NSObject {
                        if !(key is NSString) {
                            return false
                        }
                        
                        if let obj = dict.objectForKey(key) {
                            if !isValid(obj, false) {
                                return false
                            }
                        } else {
                            return false
                        }
                    } else {
                        return false
                    }
                }
            } else {
                if (obj is NSString) || (obj is NSNumber) || (obj is JSONBool) {
                    return !rootObject
                } else {
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
