//
//  _JSONWriting.swift
//  Swerver
//
//  Created by Julius Parishy on 12/13/15.
//  Copyright © 2015 Julius Parishy. All rights reserved.
//

import Foundation

extension NSJSONSerialization {
    public class func _impl_swerver_dataWithJSONObject(obj: [JSONEncodable], options opt: NSJSONWritingOptions) throws -> NSData {
        let prettyPrinted = ((opt.rawValue | NSJSONWritingOptions.PrettyPrinted.rawValue) == 0)
        let output = try obj.JSONString(prettyPrinted, indentationLevel: 0)
        let bytes = output.bridge().swerver_cStringUsingEncoding(NSUTF8StringEncoding)
        return NSData(bytes: bytes, length: bytes.count)
    }

    public class func _impl_swerver_dataWithJSONObject(obj: [String:JSONEncodable], options opt: NSJSONWritingOptions) throws -> NSData {
        let prettyPrinted = ((opt.rawValue | NSJSONWritingOptions.PrettyPrinted.rawValue) == 0)
        let output = try obj.JSONString(prettyPrinted, indentationLevel: 0)
        let bytes = output.bridge().swerver_cStringUsingEncoding(NSUTF8StringEncoding)
        return NSData(bytes: bytes, length: bytes.count)
    }

    public class func _impl_swerver_dataWithJSONObject<T : JSONEncodable>(obj: [T], options opt: NSJSONWritingOptions) throws -> NSData {
        let validObj = obj.map {
            v in
            return v as JSONEncodable
        }

        return try _impl_swerver_dataWithJSONObject(validObj, options: opt)
    }

    public class func _impl_swerver_dataWithJSONObject<T : JSONEncodable>(obj: [String:T], options opt: NSJSONWritingOptions) throws -> NSData {
        let validObj = mapDict(obj) {
            (k: String, v: T) -> (String, JSONEncodable) in
            return (k, v as JSONEncodable)
        }

        return try _impl_swerver_dataWithJSONObject(validObj, options: opt)
    }
}

private func mapDict<K : Hashable, V, OK : Hashable, OV>(dict: Dictionary<K,V>, f: ((K,V) -> (OK,OV))) -> Dictionary<OK, OV> {
    var out = Dictionary<OK, OV>()
    for (k,v) in dict {
        let (ok,ov) = f(k, v)
        out[ok] = ov
    }
    return out
}

private func Indentation(level: Int) -> String {
    return String(count: level, repeatedValue: Character("\t"))
}

extension JSONEncodable {
    private func JSONString(prettyPrinted: Bool, indentationLevel: Int) throws -> String {
        if let s = self as? String {
            return try s.JSONString(prettyPrinted)
        } else if let s = self as? Int {
            return try s.JSONString(prettyPrinted)
        } else if let s = self as? Bool {
            return try s.JSONString(prettyPrinted)
        } else if let s = self as? Dictionary<String, JSONEncodable> {
            return try s.JSONString(prettyPrinted, indentationLevel: indentationLevel)
        } else if let s = self as? Dictionary<String, Int> {
            return try s.JSONString(prettyPrinted, indentationLevel: indentationLevel)
        } else if let s = self as? Dictionary<String, Double> {
            return try s.JSONString(prettyPrinted, indentationLevel: indentationLevel)
        } else if let s = self as? Dictionary<String, Float> {
            return try s.JSONString(prettyPrinted, indentationLevel: indentationLevel)
        } else if let s = self as? Dictionary<String, Bool> {
            return try s.JSONString(prettyPrinted, indentationLevel: indentationLevel)
        } else if let s = self as? Dictionary<String, String> {
            return try s.JSONString(prettyPrinted, indentationLevel: indentationLevel)
        } else if let s = self as? Array<JSONEncodable> {
            return try s.JSONString(prettyPrinted, indentationLevel: indentationLevel)
        } else if let s = self as? Array<Int> {
            return try s.JSONString(prettyPrinted, indentationLevel: indentationLevel)
        } else if let s = self as? Array<Double> {
            return try s.JSONString(prettyPrinted, indentationLevel: indentationLevel)
        } else if let s = self as? Array<Float> {
            return try s.JSONString(prettyPrinted, indentationLevel: indentationLevel)
        } else if let s = self as? Array<Bool> {
            return try s.JSONString(prettyPrinted, indentationLevel: indentationLevel)
        } else if let s = self as? Array<String> {
            return try s.JSONString(prettyPrinted, indentationLevel: indentationLevel)
        } else {
            throw JSONError.InvalidInput
        }
    }
}

extension Dictionary {
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

        let keys: [Key] = Array(self.keys).sort { (k1: Key, k2: Key) -> Bool in
            if let s1 = k1 as? String, s2 = k2 as? String {
                return s1 < s2
            } else {
                return false
            }
        }

        for k in keys {
            let v = self[k]

            if let k = k as? String, v = v as? JSONEncodable {
                if prettyPrinted {
                    output += Indentation(indentationLevel + 1)
                }
                
                output += try k.JSONString(prettyPrinted)

                output += ":"
                if prettyPrinted {
                    output += " "
                }
                
                output += try v.JSONString(prettyPrinted, indentationLevel: indentationLevel)
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

extension Array {
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
            
            if let v = v as? String {
                output += try v.JSONString(prettyPrinted)
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

extension String {
    private func JSONString(prettyPrinted: Bool) throws -> String {
        return "\"\(self)\""
    }
}

extension Int {
    private func JSONString(prettyPrinted: Bool) throws -> String {
        return "\(self)"
    }
}

extension Bool {
    private func JSONString(prettyPrinted: Bool) throws -> String {
        return self ? "true" : "false"
    }
}

