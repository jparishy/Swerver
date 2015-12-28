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
    func rawValueForWriting() throws -> Any
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
    
    public func rawValueForWriting() throws -> Any {
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
    
    public override func rawValueForWriting() throws -> Any {
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
    
    public override func rawValueForWriting() throws -> Any {
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
    
    public override func rawValueForWriting() throws -> Any {
        return value()
    }
}

public extension Bool {
    public init(_ boolProperty: BoolProperty) {
        self.init(boolProperty.value())
    }
}

public class Model {
    public required init() {}
    public class var table: String { get { return "" } }
    public class var columns: [String] { get { return [] } }
    public class var primaryKey: String { get { return "" } }
    public var properties: [BaseProperty] { get { return [] } }
    var transaction: Transaction? { get { return nil } }
    
    public func JSON() throws -> [String:Any] {
        return try JSONDictionaryFromModel(self)
    }
}

public extension SequenceType where Generator.Element == Model {
    public func JSON() throws -> [Any] {
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
            } else if let b = obj as? Bool {
                str = (b ? "true" : "false").bridge()
            } else {
                str = obj as! NSString
            }
            
            try ModelsMap(m.properties)[k]?.databaseReadFromValue(str.bridge())
        }
    }
    
    return m
}

public func JSONDictionariesFromModels(models: [Model]) throws -> [Any] {
    var array: [Any] = []
    for m in models {
        array.append(try JSONDictionaryFromModel(m))
    }
    return array
}

public func JSONDictionaryFromModel(m: Model) throws -> [String:Any] {
    
    var d = Dictionary<String, Any>()
    
    for (k,v) in ModelsMap(m.properties) {
        let vv = try v.rawValueForWriting()
        d[k] = vv
    }
    
    return d
}
