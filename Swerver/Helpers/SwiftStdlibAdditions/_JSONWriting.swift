//
//  _JSONWriting.swift
//  Swerver
//
//  Created by Julius Parishy on 12/13/15.
//  Copyright © 2015 Julius Parishy. All rights reserved.
//

import Foundation

extension NSJSONSerialization {
    public class func _impl_swerver_dataWithJSONObject(obj: AnyObject, options opt: NSJSONWritingOptions) throws -> NSData {
        if !swerver_isValidJSONObject(obj) {
            throw Error.InvalidInput
        }
        
        if let obj = obj as? NSObject {
            let prettyPrinted = ((opt.rawValue | NSJSONWritingOptions.PrettyPrinted.rawValue) == 0)
            let output = try obj.JSONObjectString(prettyPrinted)
            let bytes = output.bridge().swerver_cStringUsingEncoding(NSUTF8StringEncoding)
            return NSData(bytes: bytes, length: bytes.count)
        } else {
            throw Error.InvalidInput
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
            throw NSJSONSerialization.Error.InvalidInput
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
            
            if let k = k as? NSString, v = v as? NSObject {
                if prettyPrinted {
                    output += Indentation(indentationLevel + 1)
                }
                
                output += try k.JSONString(prettyPrinted)
                output += ":"
                if prettyPrinted {
                    output += " "
                }
                output += try v.JSONObjectString(prettyPrinted)
            } else {
                throw NSJSONSerialization.Error.InvalidInput
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
        return output.bridge()
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
            } else {
                throw NSJSONSerialization.Error.InvalidInput
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
        return output.bridge()
    }
}

extension NSString {
    private func JSONString(prettyPrinted: Bool) throws -> String {
        return "\"\(self)\""
    }
}

extension NSNumber {
    private func JSONString(prettyPrinted: Bool) throws -> String {
        return "\(self)"
    }
}

