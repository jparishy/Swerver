//
//  _JSONReading.swift
//  Swerver
//
//  Created by Julius Parishy on 12/12/15.
//  Copyright © 2015 Julius Parishy. All rights reserved.
//

import Foundation

public class JSONBool : CustomStringConvertible {
    let value: Bool
    init(bool value: Bool) {
        self.value = value
    }
    
    convenience init(string value: String) {
        self.init(bool: value == "true")
    }
    
    var stringValue: String {
        return value ? "true" : "false"
    }
    
    public var description: String {
        return "<JSONBool: \(stringValue)>"
    }
}

extension NSJSONSerialization {
    
    internal class func _impl_swerver_JSONObjectWithData(data: NSData, options opt: NSJSONReadingOptions) throws -> AnyObject {
    
        class Node {
            enum Type {
                case Dictionary
                case Array
                case String
                case Number
                case Boolean
            }
            
            init(_ type: Type) {
                self.type = type
                switch type {
                    case .Dictionary:
                        dictionaryValue = NSMutableDictionary()
                    case .Array:
                        arrayValue = NSMutableArray()
                    case .String:
                        closed = true
                        break
                    case .Number:
                        closed = true
                        break
                    case .Boolean:
                        closed = true
                        break
                }
            }
            
            var parent: Node? = nil
            var nextDictionaryKey: NSString?
            var closed = false
            
            var type: Type
            
            var dictionaryValue: NSMutableDictionary? = nil
            var arrayValue: NSMutableArray? = nil
            var stringValue: NSString? = nil
            var numberValue: NSNumber? = nil
            var booleanValue: JSONBool? = nil
            
            func equalTo(node: Node) -> Bool {
                switch (type, node.type) {
                    case (.Dictionary, .Dictionary): return dictionaryValue?.isEqual(node.dictionaryValue) ?? false
                    case (.Array, .Array): return arrayValue?.isEqual(node.arrayValue) ?? false
                    case (.String, .String): return stringValue == node.stringValue
                    case (.Number, .Number): return numberValue == node.numberValue
                    default: return false
                }
            }
        }
        
        enum TokenType {
            case Undetermined /* wtfbbq */
            case Key          /* \"str\" or str */
            case Value        /* \"str\", str, or 3 */
            case Colon        /* : */
            case MaybeNext    /* ',' or end-of-value */
        }
        
        if let string = NSString(bytes: data.bytes, length: data.length, encoding: NSUTF8StringEncoding) {
        
            var rootNode: Node?
            var currentNode: Node?
            
            var nextExpectedToken: TokenType = .Undetermined
            
            let scanner = JSONStringScanner(string: string.bridge())
            
            let invalidUnquotedToken = {
                (string: NSString) -> Bool in
                
                let alphaNumeric = NSCharacterSet.alphanumericCharacterSet()
                for i in 0..<string.length {
                    if !alphaNumeric.characterIsMember(string.characterAtIndex(i)) {
                        return true
                    }
                }
                
                return false
            }
            
            repeat {
            
                switch nextExpectedToken {
                
                /*
                 * Before we even have the root node
                 */
                case .Undetermined:
                    if rootNode != nil {
                        continue
                    }
                    
                    if scanner.scanString("{", intoString: nil) {
                        rootNode = Node(.Dictionary)
                        nextExpectedToken = .Key
                    } else if scanner.scanString("[", intoString: nil) {
                        rootNode = Node(.Array)
                        nextExpectedToken = .Value
                    } else {
                        throw JSONError.UnexpectedToken(message: "Fragments are unsupported.", location: scanner.scanLocation)
                    }
                    
                    currentNode = rootNode
                    
                /*
                 * Looking for a dictionary key
                 */
                case .Key:
                    var string: NSString? = nil
                    if scanner.scanString("\"", intoString: nil) {
                        var key: NSString? = nil
                        if scanner.scanUpToString("\"", intoString: &key) {
                            scanner.scanString("\"", intoString: nil)
                            currentNode?.nextDictionaryKey = key
                            nextExpectedToken = .Colon
                        } else {
                            throw JSONError.UnexpectedToken(message: "Expected quote to end key.", location: scanner.scanLocation)
                        }
                    } else if scanner.scanUpToString(":", intoString: &string) {
                        if let string = string {
                            if invalidUnquotedToken(string) {
                                throw JSONError.UnexpectedToken(message: "Invalid key in dictionary.", location: scanner.scanLocation)
                            }
                            
                            currentNode?.nextDictionaryKey = string
                            nextExpectedToken = .Colon
                            
                        } else {
                            throw JSONError.UnexpectedToken(message: "Expected dictionary key.", location: scanner.scanLocation)
                        }
                    } else if scanner.scanString("}", intoString: nil) {
                        
                        if let current = currentNode, dict = current.dictionaryValue where current.type == .Dictionary {
                            if dict.count == 0 {
                                current.closed = true
                            } else {
                                throw JSONError.UnexpectedToken(message: "Expected dictionary key, got '}'", location: scanner.scanLocation)
                            }
                        } else {
                            throw JSONError.UnexpectedToken(message: "Expected dictionary key, got '}'", location: scanner.scanLocation)
                        }
                    } else if scanner.scanString("]", intoString: nil) {
                        
                        if let current = currentNode, array = current.arrayValue where current.type == .Array {
                            if array.count == 0 {
                                current.closed = true
                            } else {
                                throw JSONError.UnexpectedToken(message: "Expected dictionary key, got '}'", location: scanner.scanLocation)
                            }
                        } else {
                            throw JSONError.UnexpectedToken(message: "Expected dictionary key, got '}'", location: scanner.scanLocation)
                        }
                    } else {
                        throw JSONError.UnexpectedToken(message: "Expected dictionary key.", location: scanner.scanLocation)
                    }
                
                /* 
                 * Values, for dictionaries or for arrays
                 */
                case .Value:
                    var string: NSString? = nil
                    
                    let parsedValue: AnyObject?
                    
                    var doubleValue: Double = 0
                    var intValue: Int = 0
            
                    if scanner.scanDouble(&doubleValue) {
                        parsedValue = NSNumber(double: doubleValue)
                        nextExpectedToken = .MaybeNext
                    } else if scanner.scanInt(&intValue) {
                        parsedValue = NSNumber(integer: intValue)
                        nextExpectedToken = .MaybeNext
                    } else if scanner.scanString("\"", intoString: nil) {
                        var value: NSString? = nil
                        scanner.scanUpToString("\"", intoString: &value)
                        
                        if let value = value {
                            scanner.scanString("\"", intoString: nil)
                            parsedValue = value
                            nextExpectedToken = .MaybeNext
                        } else {
                            throw JSONError.UnexpectedToken(message: "Expected value.", location: scanner.scanLocation)
                        }
                    } else if scanner.scanString("{", intoString: nil) {
                        let parent = currentNode
                        
                        currentNode = Node(.Dictionary)
                        currentNode?.parent = parent
                        
                        nextExpectedToken = .Key
                        parsedValue = nil
                        
                    } else if scanner.scanString("[", intoString: nil) {
                    
                        let parent = currentNode
                        
                        currentNode = Node(.Array)
                        currentNode?.parent = parent
                        
                        nextExpectedToken = .Value
                        parsedValue = nil
                        
                    } else if scanner.scanUpToString(",", intoString: &string) {
                        if let string = string where  invalidUnquotedToken(string) {
                            throw JSONError.UnexpectedToken(message: "Value contains invalid characters", location: scanner.scanLocation)
                        }
                        
                        scanner.scanString(",", intoString: nil)
                        
                        if let current = currentNode {
                            switch current.type {
                            case .Dictionary:
                                nextExpectedToken = .Key
                            case .Array:
                                nextExpectedToken = .Value
                            default:
                                nextExpectedToken = .Undetermined
                            }
                        } else {
                            nextExpectedToken = .Undetermined
                        }
                        
                        if string == "true" {
                            parsedValue = JSONBool(bool: true)
                        } else if string == "false" {
                            parsedValue = JSONBool(bool: false)
                        } else {
                            parsedValue = string
                        }
                        
                    } else if scanner.scanUpToString("}", intoString: &string) {
                        if let string = string where  invalidUnquotedToken(string) {
                            throw JSONError.UnexpectedToken(message: "Value contains invalid characters", location: scanner.scanLocation)
                        }
                        
                        nextExpectedToken = .MaybeNext
                        
                        if string == "true" {
                            parsedValue = JSONBool(bool: true)
                        } else if string == "false" {
                            parsedValue = JSONBool(bool: false)
                        } else {
                            parsedValue = string
                        }
                        
                    } else if scanner.scanUpToString("]", intoString: &string) {
                        if let string = string where  invalidUnquotedToken(string) {
                            throw JSONError.UnexpectedToken(message: "Value contains invalid characters", location: scanner.scanLocation)
                        }
                        
                        nextExpectedToken = .MaybeNext
                        
                        if string == "true" {
                            parsedValue = JSONBool(bool: true)
                        } else if string == "false" {
                            parsedValue = JSONBool(bool: false)
                        } else {
                            parsedValue = string
                        }
                        
                    } else {
                        throw JSONError.UnexpectedToken(message: "Invalid end of value.", location: scanner.scanLocation)
                    }
                    
                    if let current = currentNode {
                        switch current.type {
                        case .Dictionary:
                            if let key = current.nextDictionaryKey, value = parsedValue {
                                current.dictionaryValue?.setObject(value, forKey: key)
                            }
            
                        case .Array:
                            if let value = parsedValue {
                                current.arrayValue?.addObject(value)
                            }
                        default:
                            throw JSONError.UnexpectedToken(message: "Invalid value.", location: scanner.scanLocation)
                        }
                    } else {
                        throw JSONError.UnexpectedToken(message: "Invalid value.", location: scanner.scanLocation)
                    }
                    
                    if nextExpectedToken == .Undetermined, let parent = currentNode?.parent {
                        currentNode = parent
                    }
                    
                /*
                 * Look for a comma or the end of the current context.
                 */
                case .MaybeNext:
                    if let current = currentNode {
                        if scanner.scanString(",", intoString: nil) {
                            switch current.type {
                            case .Dictionary:
                                nextExpectedToken = .Key
                            case .Array:
                                nextExpectedToken = .Value
                            default:
                                throw JSONError.UnexpectedToken(message: "Unexpected ','", location: scanner.scanLocation)
                            }
                        } else if scanner.scanString("]", intoString: nil) {
                            if let current = currentNode, parent = current.parent, key = parent.nextDictionaryKey {
                                if current.type != .Array {
                                    throw JSONError.UnexpectedToken(message: "Unexpected ']'", location: scanner.scanLocation)
                                }
                                switch parent.type {
                                case .Dictionary:
                                    if let array = current.arrayValue {
                                        parent.dictionaryValue?.setObject(array, forKey: key)
                                        current.closed = true
                                        currentNode = parent
                                        nextExpectedToken = .MaybeNext
                                    } else {
                                        throw JSONError.UnexpectedToken(message: "Unexpected nested type.", location: scanner.scanLocation)
                                    }
                                case .Array:
                                    if let array = current.arrayValue {
                                        parent.arrayValue?.addObject(array)
                                        current.closed = true
                                        currentNode = parent
                                        nextExpectedToken = .MaybeNext
                                    } else {
                                        throw JSONError.UnexpectedToken(message: "Unexpected nested type.", location: scanner.scanLocation)
                                    }
                                default:
                                    throw JSONError.UnexpectedToken(message: "Unexpected end of dictionary.", location: scanner.scanLocation)
                                }
                            } else {
                                if let root = rootNode, current = currentNode where current.equalTo(root) {
                                    currentNode?.closed = true
                                }
                                continue
                            }
                            
                        } else if scanner.scanString("}", intoString: nil) {
                            if let current = currentNode, parent = current.parent {
                                if current.type != .Dictionary {
                                    throw JSONError.UnexpectedToken(message: "Unexpected '}'", location: scanner.scanLocation)
                                }
                                switch parent.type {
                                case .Dictionary:
                                    if let key = parent.nextDictionaryKey, dictionary = current.dictionaryValue {
                                        parent.dictionaryValue?.setObject(dictionary, forKey: key)
                                        current.closed = true
                                        currentNode = parent
                                        nextExpectedToken = .MaybeNext
                                    } else {
                                        throw JSONError.UnexpectedToken(message: "Unexpected nested type.", location: scanner.scanLocation)
                                    }
                                case .Array:
                                    if let dictionary = current.dictionaryValue {
                                        parent.arrayValue?.addObject(dictionary)
                                        current.closed = true
                                        currentNode = parent
                                        nextExpectedToken = .MaybeNext
                                    } else {
                                        throw JSONError.UnexpectedToken(message: "Unexpected nested type.", location: scanner.scanLocation)
                                    }
                                default:
                                    throw JSONError.UnexpectedToken(message: "Unexpected end of dictionary.", location: scanner.scanLocation)
                                }
                            } else {
                                if let root = rootNode, current = currentNode where current.equalTo(root) {
                                    currentNode?.closed = true
                                }
                                continue
                            }
                        
                        } else if scanner.scanLocation != scanner.string.bridge().length - 1 {
                            throw JSONError.UnexpectedToken(message: "Unexpected end of context.", location: scanner.scanLocation)
                        }
                    } else {
                        throw JSONError.UnexpectedToken(message: "Unexpected end of context.", location: scanner.scanLocation)
                    }
            
                /*
                 * Colon for dictionary key:value separating
                 */
                case .Colon:
                    var result: NSString? = nil
                    if scanner.scanString(":", intoString: &result) == false {
                        throw JSONError.UnexpectedToken(message: "Expected ':'", location: scanner.scanLocation)
                    }
                    
                    nextExpectedToken = .Value
                    
                }
                
            } while(!scanner.atEnd)
            
            if let currentNode = currentNode where currentNode.closed == false {
                throw JSONError.UnexpectedToken(message: "Unexpected end of file ", location: scanner.scanLocation)
            }
            
            if let rootNode = rootNode {
                switch rootNode.type {
                case .Dictionary:
                    if let dict = rootNode.dictionaryValue {
                        return dict
                    }
                    
                case .Array:
                    if let arr = rootNode.arrayValue {
                        return arr
                    }
                    
                default: break
                }
                
                throw JSONError.UnexpectedToken(message: "Invalid root object or unexpected end of data", location: scanner.scanLocation)
                
            } else {
                throw JSONError.UnexpectedToken(message: "Could not find root object in data", location: scanner.scanLocation)
            }
        } else {
            throw JSONError.InvalidInput
        }
    }
}

/*
 * NSScanner replacement that better suits the needs of a JSON parser,
 * namely being able to handle escaped characters within JSON strings.
 */
private class JSONStringScanner {
    let string: String
    
    private var _scanLocation = 0
    var scanLocation: Int {
        return _scanLocation
    }
    
    var atEnd: Bool {
        return scanLocation >= string.bridge().length
    }
    
    init(string: String) {
        self.string = string
    }
    
    private func advance() {
        let whitespace = NSCharacterSet.whitespaceAndNewlineCharacterSet()
        let sstring = self.string.bridge()
        
        var outScanLocation = self.scanLocation
        for i in (self.scanLocation..<sstring.length) {
            if whitespace.characterIsMember(sstring.characterAtIndex(i)) {
                continue
            } else {
                outScanLocation = i
                break
            }
        }
        
        _scanLocation = outScanLocation
    }
    
    func scanUpToString(string: String, intoString result: UnsafeMutablePointer<NSString?>) -> Bool {
        let input = string.bridge()
        let inputLength = input.length
        let sstring = self.string.bridge()
        
        var output: NSString? = nil
        var outScanLocation: Int = 0
        
        var i = scanLocation
        repeat {
            if i + inputLength >= sstring.length {
                break
            }
            
            var sub = sstring.substringWithRange(NSMakeRange(i, inputLength))
            var loc = i
            if sub == "\\" && (i + 1 < sstring.length) {
                sub = sstring.substringWithRange(NSMakeRange(i, 2))
                loc = i + 1
                i += 1
            }
            
            if sub == input.bridge() {
                let scanned = sstring.substringWithRange(NSMakeRange(self.scanLocation, loc - self.scanLocation))
                output = NSString(string: scanned.bridge().swerver_stringByReplacingOccurrencesOfString("\\\"", withString: "\""))
                outScanLocation = loc
                break
            }
            
            i += 1
        } while (i < sstring.length)
        
        if let output = output {
            if result != nil {
                result.memory = NSString(string: output.bridge())
            }
            _scanLocation = outScanLocation
            return true
        }
        
        return false
    }
    
    func scanString(string: String, intoString result: UnsafeMutablePointer<NSString?>) -> Bool {
        
        advance()
        
        let input = string.bridge()
        let inputLength = input.length
        let sstring = self.string.bridge()
        
        if scanLocation + inputLength > sstring.length {
            return false
        }
        
        let sub = sstring.substringWithRange(NSMakeRange(scanLocation, inputLength))
        
        if sub == input.bridge() {
            if result != nil {
                result.memory = string.bridge()
            }
            _scanLocation = scanLocation + inputLength
            return true
        }
        
        return false
    }
    
    func scanInt(result: UnsafeMutablePointer<Int>) -> Bool {
    
        advance()
        
        let sstring = self.string.bridge()
        
        let numbers = NSCharacterSet.decimalDigitCharacterSet()
        
        var endOfInt: Int = self.scanLocation
        
        for i in (self.scanLocation..<sstring.length) {
            
            let char = sstring.characterAtIndex(i)
            if numbers.characterIsMember(char) == false {
                endOfInt = i
                break
            }
        }
        
        if endOfInt > self.scanLocation {
            let sub = sstring.substringWithRange(NSMakeRange(self.scanLocation, endOfInt - self.scanLocation))
            
            if result != nil, let output = Int(sub) {
                result.memory = output
            }
            
            _scanLocation = endOfInt
            
            return true
        }
        
        return false
    }
    
    func scanDouble(result: UnsafeMutablePointer<Double>) -> Bool {
        
        advance()
        
        let sstring = self.string.bridge()
        
        let numbers = NSCharacterSet.decimalDigitCharacterSet()
        
        var endOfDouble: Int = self.scanLocation
        var foundDecimalPoint = false
        
        for i in (self.scanLocation..<sstring.length) {
            
            let char = sstring.characterAtIndex(i)
            let isValidDecimal = Character(UnicodeScalar(char)) == Character(".")
            if numbers.characterIsMember(char) == false || isValidDecimal {
                endOfDouble = i
                if isValidDecimal && !foundDecimalPoint {
                    foundDecimalPoint = true
                } else {
                    break
                }
            }
        }
        
        if endOfDouble > self.scanLocation && foundDecimalPoint {
            let sub = sstring.substringWithRange(NSMakeRange(self.scanLocation, endOfDouble - self.scanLocation))
            
            if result != nil, let output = Double(sub) {
                result.memory = output
            }
            
            _scanLocation = endOfDouble
            
            return true
        }
        
        return false
    }
}
