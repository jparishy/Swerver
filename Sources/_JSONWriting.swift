//
//  _JSONWriting.swift
//  Swerver
//
//  Created by Julius Parishy on 12/13/15.
//  Copyright © 2015 Julius Parishy. All rights reserved.
//

import Foundation

extension NSJSONSerialization {
    public class func _impl_swerver_dataWithJSONObject(obj: Any, options opt: NSJSONWritingOptions) throws -> NSData {

        /*
         * Lots of f'd up stuff going on here.
         * 1. Foundation doesn't have JSON serialization yet, just deserialization
         * 2. Foundation's isValidJSONObject() does not work with NSDictionary or NSArray
         * 3. We have to use NSDictionary and NSArray because OS Swift doesn't support casting Swift.Dictionary &
         *    Swift.Array to verions with Any, ex. Dictionary<String, Int> is not castable to Dictionary<String, Any>
         *    even though it should be. This is to be fixed in the future.
         * 4. This is probably why they don't have JSON serialization yet, but this is a web framework
         *    so _we_ need it. So we hack around and just don't validate.
         */
        /*
        if !isValidJSONObject(obj) {
            throw JSONError.InvalidInput
        }
        */
        
        if let obj = obj as? NSObject {
            let prettyPrinted = ((opt.rawValue | NSJSONWritingOptions.PrettyPrinted.rawValue) == 0)
            let output = try obj.JSONObjectString(prettyPrinted)
            let bytes = output.bridge().swerver_cStringUsingEncoding(NSUTF8StringEncoding)
            return NSData(bytes: bytes, length: bytes.count)
        } else {
            throw JSONError.InvalidInput
        }
    }
}

private func Indentation(level: Int) -> String {
    return String(count: level, repeatedValue: Character("\t"))
}

extension NSObject {
    private func JSONObjectString(prettyPrinted: Bool, indentationLevel: Int? = nil) throws -> String {
        
        let level: Int
        if let il = indentationLevel {
            level = il
        } else {
            level = 0
        }
        
        if let dictionary = self as? NSDictionary {
            return try dictionary.JSONString(prettyPrinted, indentationLevel: level)
        } else if let array = self as? NSArray {
            return try array.JSONString(prettyPrinted, indentationLevel: level)
        } else if let string = self as? NSString {
            return try string.JSONString(prettyPrinted)
        } else if let number = self as? NSNumber {
            return try number.JSONString(prettyPrinted)
        } else {
            throw JSONError.InvalidInput
        }
    }
}

extension NSDictionary {
    private func JSONString(prettyPrinted: Bool, indentationLevel: Int) throws -> String {
        var output = ""
        
        if prettyPrinted {
            output += Indentation(indentationLevel)
        }
        output += "{"
        
        if prettyPrinted {
            output += "\n"
        }
        
        var index = 0
        for (k,v) in self {
            
            if let k = k as? NSString {
                if prettyPrinted {
                    output += Indentation(indentationLevel + 1)
                }
                
                output += try k.JSONString(prettyPrinted)
                output += ":"
                if prettyPrinted {
                    output += " "
                }
                if let v = v as? NSObject {
                    output += try v.JSONObjectString(prettyPrinted)
                } else if let v = v as? Bool {
                    output += try v.JSONString(prettyPrinted)
                }
            } else {
                throw JSONError.InvalidInput
            }
            
            if index < self.count - 1 {
                output += ","
                if prettyPrinted {
                    output += "\n"
                }
            }
            
            index += 1
        }
        
        if prettyPrinted {
            output += "\n"
            output += Indentation(indentationLevel)
        }
        
        output += "}"
        return output
    }
}

extension NSArray {
    private func JSONString(prettyPrinted: Bool, indentationLevel: Int) throws -> String {
        var output = ""
        
        if prettyPrinted {
            output += Indentation(indentationLevel)
        }
        
        output += "["
        
        if prettyPrinted {
            output += "\n"
        }
        
        var index = 0
        for v in self {
            
            if let v = v as? NSObject {
                output += try v.JSONObjectString(prettyPrinted, indentationLevel: indentationLevel + 1)
            } else if let v = v as? Bool {
                output += try v.JSONString(prettyPrinted)
            } else {
                throw JSONError.InvalidInput
            }
            
            if index < self.count - 1 {
                output += ","
                if prettyPrinted {
                    output += "\n"
                }
            }
            
            index += 1
        }
        
        if prettyPrinted {
            output += "\n"
            output += Indentation(indentationLevel)
        }
        
        output += "]"
        return output
    }
}

extension NSString {
    private func JSONString(prettyPrinted: Bool) throws -> String {
        return "\"\(self.bridge())\""
    }
}

extension NSNumber {
    private func JSONString(prettyPrinted: Bool) throws -> String {
        if doubleValue % 1 == 0 {
            return "\(doubleValue)"
        } else {
            return "\(integerValue)"
        }
    }
}

extension Bool {
    private func JSONString(prettyPrinted: Bool) throws -> String {
        return self ? "true" : "false"
    }
}

