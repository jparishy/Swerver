//
//  Model.swift
//  Swerver
//
//  Created by Julius Parishy on 12/11/15.
//  Copyright © 2015 Julius Parishy. All rights reserved.
//

import Foundation

enum ModelError : ErrorType {
    case MustOverrideInSubclass
}

public protocol BaseProperty {
    var dirty: Bool { get }
    func databaseReadFromValue(value: String) throws
    func databaseValueForWriting() throws -> String
    func rawValueForWriting() throws -> NSObject
}

public class Property<T> : BaseProperty, CustomStringConvertible {
    let column: String
    
    internal var _dirty = false
    public var dirty: Bool {
        return _dirty
    }
    
    private var internalValue: T
    
    private init(column: String, initialValue: T) {
        self.column = column
        self.internalValue = initialValue
    }
    
    func update(value: T) -> T {
        internalValue = value
        _dirty = true
        
        return internalValue
    }
    
    func value() -> T {
        return internalValue
    }
    
    public func databaseReadFromValue(value: String) throws {
        throw ModelError.MustOverrideInSubclass
    }
    
    public func databaseValueForWriting() throws -> String {
        throw ModelError.MustOverrideInSubclass
    }
    
    public func rawValueForWriting() throws -> NSObject {
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
    init(column: String) {
        super.init(column: column, initialValue: "")
    }
    
    override public func databaseReadFromValue(value: String) {
        internalValue = value
    }
    
    override public func databaseValueForWriting() -> String {
        return "'\(value())'"
    }
    
    public override func rawValueForWriting() throws -> NSObject {
        return NSString(string: value())
    }
}

extension String {
    init(_ stringProperty: StringProperty) {
        self.init(stringProperty.value())
    }
}

public class IntProperty : Property<Int> {
    init(column: String) {
        super.init(column: column, initialValue: 0)
    }
    
    override public func databaseReadFromValue(value: String) {
        internalValue = value.bridge().integerValue
    }
    
    override public func databaseValueForWriting() -> String {
        return String(value())
    }
    
    public override func rawValueForWriting() throws -> NSObject {
        return NSNumber(integer: value())
    }
}

extension Int {
    init(_ intProperty: IntProperty) {
        self.init(intProperty.value())
    }
}

public protocol Model : class {
    init()
    static var table: String { get }
    static var columns: [String] { get }
    static var primaryKey: String { get }
    var map: [String:BaseProperty] { get }
    var transaction: Transaction? { get set }
}

func ModelFromJSONDictionary<T : Model>(JSON: NSDictionary) throws -> T {
    let m = T()
    for (k,_) in m.map {
        if let v = JSON[k.bridge()] {
            let str = String(v)
            try m.map[k]?.databaseReadFromValue(str)
        }
    }
    
    return m
}

func JSONDictionariesFromModels<T : Model>(models: [T]) throws -> NSArray {
    let array = NSMutableArray()
    for m in models {
        array.addObject(try JSONDictionaryFromModel(m))
    }
    return array
}

func JSONDictionaryFromModel<T : Model>(m: T) throws -> NSDictionary {
    
    let d = NSMutableDictionary()
    
    for (k,v) in m.map {
        let vv = try v.rawValueForWriting()
        d.setObject(vv, forKey: k.bridge())
    }
    
    return d
}
