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
        return "\'\(value())\'"
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
