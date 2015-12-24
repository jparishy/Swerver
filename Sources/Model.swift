//
//  Model.swift
//  Swerver
//
//  Created by Julius Parishy on 12/11/15.
//  Copyright © 2015 Julius Parishy. All rights reserved.
//

import Foundation
import CoreFoundation

enum ModelError : ErrorType {
    case MustOverrideInSubclass
}

public protocol BaseProperty {
    var column: String { get }
    var dirty: Bool { get }
    func databaseReadFromValue(value: String) throws
    func databaseValueForWriting() throws -> String
    func rawValueForWriting() throws -> AnyObject
}

public class Property<T> : BaseProperty, CustomStringConvertible {
    public let column: String
    
    public var hashValue: Int {
        return column.hashValue
    }
    
    internal var _dirty = false
    public var dirty: Bool {
        return _dirty
    }
    
    private var internalValue: T
    
    private init(column: String, initialValue: T) {
        self.column = column
        self.internalValue = initialValue
    }
    
    public func update(value: T) -> T {
        internalValue = value
        _dirty = true
        
        return internalValue
    }
    
    public func value() -> T {
        return internalValue
    }
    
    public var properties: [BaseProperty] {
        return []
    }
    
    public func databaseReadFromValue(value: String) throws {
        throw ModelError.MustOverrideInSubclass
    }
    
    public func databaseValueForWriting() throws -> String {
        throw ModelError.MustOverrideInSubclass
    }
    
    public func rawValueForWriting() throws -> AnyObject {
        throw ModelError.MustOverrideInSubclass
    }
    
    public var description: String {
        do {
            return try databaseValueForWriting()
        } catch {
            return ""
        }
    }
}

public class StringProperty : Property<String> {
    public init(column: String) {
        super.init(column: column, initialValue: "")
    }
    
    override public func databaseReadFromValue(value: String) {
        internalValue = value
    }
    
    override public func databaseValueForWriting() -> String {
        return "'\(value())'"
    }
    
    public override func rawValueForWriting() throws -> AnyObject {
        return NSString(string: value())
    }
}

public extension String {
    public init(_ stringProperty: StringProperty) {
        self.init(stringProperty.value())
    }
}

public class IntProperty : Property<Int> {
    public init(column: String) {
        super.init(column: column, initialValue: 0)
    }
    
    override public func databaseReadFromValue(value: String) {
        internalValue = value.bridge().integerValue
    }
    
    override public func databaseValueForWriting() -> String {
        return String(value())
    }
    
    public override func rawValueForWriting() throws -> AnyObject {
        return NSNumber(integer: value())
    }
}

public extension Int {
    public init(_ intProperty: IntProperty) {
        self.init(intProperty.value())
    }
}

public class BoolProperty : Property<Bool> {
    public init(column: String) {
        super.init(column: column, initialValue: false)
    }
    
    override public func databaseReadFromValue(value: String) {
        internalValue = (value.bridge() == "t" || value.bridge() == "true") ? true : false
    }
    
    override public func databaseValueForWriting() -> String {
        return value() ? "true" : "false"
    }
    
    public override func rawValueForWriting() throws -> AnyObject {
        return JSONBool(bool: value())
    }
}

extension Bool {
    init(_ boolProperty: BoolProperty) {
        self.init(boolProperty.value())
    }
}

public class Model {
    public required init() {}
    class var table: String { get { return "" } }
    class var columns: [String] { get { return [] } }
    class var primaryKey: String { get { return "" } }
    var properties: [BaseProperty] { get { return [] } }
    var transaction: Transaction? { get { return nil } }
    
    func JSON() throws -> NSDictionary {
        return try JSONDictionaryFromModel(self)
    }
}

public extension SequenceType where Generator.Element == Model {
    public func JSON() throws -> NSArray {
        let models = Array(self)
        return try JSONDictionariesFromModels(models)
    }
}

internal func ModelsMap(props: [BaseProperty]) -> [String:BaseProperty] {
    var map: [String:BaseProperty] = [:]
    for prop in props {
        map[prop.column] = prop
    }
    return map
}

public func ModelFromJSONDictionary<T : Model>(JSON: NSDictionary) throws -> T {
    let m = T()
    for (k,_) in ModelsMap(m.properties) {
        if let v = JSON[k.bridge()] {
            let obj = v
            let str: NSString
            if let num = obj as? NSNumber {
                if num.doubleValue % 1 == 0 {
                    str = "\(num.integerValue)".bridge()
                } else {
                    str = "\(num.doubleValue)".bridge()
                }
            } else if let b = obj as? JSONBool {
                str = b.stringValue.bridge()
            } else {
                str = obj as! NSString
            }
            
            try ModelsMap(m.properties)[k]?.databaseReadFromValue(str.bridge())
        }
    }
    
    return m
}

public func JSONDictionariesFromModels(models: [Model]) throws -> NSArray {
    let array = NSMutableArray()
    for m in models {
        array.addObject(try JSONDictionaryFromModel(m))
    }
    return array
}

public func JSONDictionaryFromModel(m: Model) throws -> NSDictionary {
    
    let d = NSMutableDictionary()
    
    for (k,v) in ModelsMap(m.properties) {
        let vv = try v.rawValueForWriting()
        d.setObject(vv, forKey: k.bridge())
    }
    
    return d
}
