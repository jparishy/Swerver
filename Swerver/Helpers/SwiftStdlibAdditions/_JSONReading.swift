//
//  _JSONReading.swift
//  Swerver
//
//  Created by Julius Parishy on 12/12/15.
//  Copyright © 2015 Julius Parishy. All rights reserved.
//

import Foundation

extension NSJSONSerialization {
    
    internal class func _impl_swerver_JSONObjectWithData(data: NSData, options opt: NSJSONReadingOptions) throws -> AnyObject {
    
        class Node {
            enum Type {
                case Dictionary
                case Array
                case String
                case Number
            }
            
            init(_ type: Type) {
                self.type = type
                switch type {
                    case .Dictionary:
                        dictionaryValue = NSMutableDictionary()
                    case .Array:
                        arrayValue = NSMutableArray()
                    case .String:
                        break
                    case .Number:
                        break
                }
            }
            
            var parent: Node? = nil
            var nextDictionaryKey: NSString?
            
            var type: Type
            
            var dictionaryValue: NSMutableDictionary? = nil
            var arrayValue: NSMutableArray? = nil
            var stringValue: NSString? = nil
            var numberValue: NSNumber? = nil
        }
        
        enum TokenType {
            case Undetermined /* wtfbbq */
            case ObjectOpen   /* { */
            case ObjectClose  /* } */
            case ArrayOpen    /* [ */
            case ArrayClose   /* ] */
            case Key          /* \"str\" or str */
            case Value        /* \"str\", str, or 3 */
            case Colon        /* : */
            case MaybeNext    /* ',' or end-of-value */
            case Quote        /* " */
        }
        
        if let string = NSString(bytes: data.bytes, length: data.length, encoding: NSUTF8StringEncoding) {
        
            var rootNode: Node?
            var currentNode: Node?
            
            var nextExpectedToken: TokenType = .Undetermined
            
            let scanner = NSScanner(string: string.bridge())
            
            let invalidUnquotedToken = {
                (string: NSString) -> Bool in
                
                let alphaNumeric = NSCharacterSet.alphanumericCharacterSet()
                for i in 0..<string.length {
                    if !alphaNumeric.characterIsMember(string.characterAtIndex(i)) {
                        return false
                    }
                }
                
                return true
            }
            
            repeat {
            
                switch nextExpectedToken {
                
                /*
                 * Before we even have the root node
                 */
                case .Undetermined:
                    if scanner.scanString("{", intoString: nil) {
                        rootNode = Node(.Dictionary)
                        nextExpectedToken = .Key
                    } else if scanner.scanString("[", intoString: nil) {
                        rootNode = Node(.Array)
                        nextExpectedToken = .Value
                    } else {
                        throw Error.InvalidInput(message: "Fragments are unsupported.")
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
                            throw Error.InvalidInput(message: "Expected quote to end key.")
                        }
                    } else if scanner.scanUpToString(":", intoString: &string) {
                        if let string = string {
                            if invalidUnquotedToken(string) {
                                throw Error.InvalidInput(message: "Invalid key in dictionary.")
                            }
                            
                            currentNode?.nextDictionaryKey = string
                            nextExpectedToken = .Colon
                            
                        } else {
                            throw Error.InvalidInput(message: "Expected dictionary key.")
                        }
                    } else {
                        throw Error.InvalidInput(message: "Expected dictionary key.")
                    }
                
                /* 
                 * Values, for dictionaries or for arrays
                 */
                case .Value:
                    var string: NSString? = nil
                    
                    let parsedValue: AnyObject?
                    
                    var floatValue: CFloat = 0
                    var intValue: CInt = 0
            
                    if scanner.scanFloat(&floatValue) {
                        parsedValue = NSNumber(double: Double(floatValue))
                        nextExpectedToken = .MaybeNext
                    } else if scanner.scanInt(&intValue) {
                        parsedValue = NSNumber(integer: Int(intValue))
                        nextExpectedToken = .MaybeNext
                    } else if scanner.scanString("\"", intoString: nil) {
                        var value: NSString? = nil
                        scanner.scanUpToString("\"", intoString: &value)
                        
                        if let value = value {
                            scanner.scanString("\"", intoString: nil)
                            parsedValue = value
                            nextExpectedToken = .MaybeNext
                        } else {
                            throw Error.InvalidInput(message: "Expected value.")
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
                            throw Error.InvalidInput(message: "Value contains invalid characters")
                        }
                        
                        scanner.scanString(",", intoString: nil)
                        parsedValue = string
                        nextExpectedToken = .MaybeNext
                        
                    } else if scanner.scanUpToString("}", intoString: &string) {
                        if let string = string where  invalidUnquotedToken(string) {
                            throw Error.InvalidInput(message: "Value contains invalid characters")
                        }
                        
                        scanner.scanString("}", intoString: nil)
                        parsedValue = string
                        nextExpectedToken = .Undetermined
                        
                    } else if scanner.scanUpToString("]", intoString: &string) {
                        if let string = string where  invalidUnquotedToken(string) {
                            throw Error.InvalidInput(message: "Value contains invalid characters")
                        }
                        
                        scanner.scanString("]", intoString: nil)
                        parsedValue = string
                        nextExpectedToken = .Undetermined
                        
                    } else {
                        throw Error.InvalidInput(message: "Invalid end of value.")
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
                            throw Error.InvalidInput(message: "Invalid value.")
                        }
                    } else {
                        throw Error.InvalidInput(message: "Invalid value.")
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
                                throw Error.InvalidInput(message: "Unexpected ','")
                            }
                        } else if scanner.scanString("]", intoString: nil) {
                            if let current = currentNode, parent = current.parent, key = parent.nextDictionaryKey {
                                switch parent.type {
                                case .Dictionary:
                                    if let array = current.arrayValue {
                                        parent.dictionaryValue?.setObject(array, forKey: key)
                                        currentNode = parent
                                        nextExpectedToken = .MaybeNext
                                    } else {
                                        throw Error.InvalidInput(message: "Unexpected nested type.")
                                    }
                                case .Array:
                                    if let array = current.arrayValue {
                                        parent.arrayValue?.addObject(array)
                                        currentNode = parent
                                        nextExpectedToken = .MaybeNext
                                    } else {
                                        throw Error.InvalidInput(message: "Unexpected nested type.")
                                    }
                                default:
                                    throw Error.InvalidInput(message: "Unexpected end of dictionary.")
                                }
                            } else {
                                continue
                            }
                            
                        } else if scanner.scanString("}", intoString: nil) {
                            if let current = currentNode, parent = current.parent{
                                switch parent.type {
                                case .Dictionary:
                                    if let key = parent.nextDictionaryKey, dictionary = current.dictionaryValue {
                                        parent.dictionaryValue?.setObject(dictionary, forKey: key)
                                        currentNode = parent
                                        nextExpectedToken = .MaybeNext
                                    } else {
                                        throw Error.InvalidInput(message: "Unexpected nested type.")
                                    }
                                case .Array:
                                    if let dictionary = current.dictionaryValue {
                                        parent.arrayValue?.addObject(dictionary)
                                        currentNode = parent
                                        nextExpectedToken = .MaybeNext
                                    } else {
                                        throw Error.InvalidInput(message: "Unexpected nested type.")
                                    }
                                default:
                                    throw Error.InvalidInput(message: "Unexpected end of dictionary.")
                                }
                            } else {
                                continue
                            }
                        
                        } else if scanner.scanLocation != scanner.string.bridge().length - 1 {
                            throw Error.InvalidInput(message: "Unexpected end of context.")
                        }
                    } else {
                        throw Error.InvalidInput(message: "Unexpected end of context.")
                    }
            
                /*
                 * Colon for dictionary key:value separating
                 */
                case .Colon:
                    var result: NSString? = nil
                    if scanner.scanString(":", intoString: &result) == false {
                        throw Error.InvalidInput(message: "Expected ':'")
                    }
                    
                    nextExpectedToken = .Value
                    
                default:
                    break
                }
                
            } while(!scanner.atEnd && scanner.scanLocation != scanner.string.bridge().length - 1)
            
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
                
                throw Error.InvalidInput(message: "Invalid root object or unexpected end of data")
                
            } else {
                throw Error.InvalidInput(message: "Could not find root object in data")
            }
        } else {
            throw Error.InvalidInput(message: "Invalid data")
        }
    }
}
