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
    func databaseReadFromValue(value: String) throws
    func databaseValueForWriting() throws -> String
}

public class Property<T> : BaseProperty, CustomStringConvertible {
    let column: String
    
    private var internalValue: T
    
    private init(column: String, initialValue: T) {
        self.column = column
        self.internalValue = initialValue
    }
    
    func update(value: T) -> T {
        internalValue = value
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
        update(value)
    }
    
    override public func databaseValueForWriting() -> String {
        return value()
    }
}

extension String {
    init(stringProperty: StringProperty) {
        self.init(stringProperty.value())
    }
}

public class IntProperty : Property<Int> {
    init(column: String) {
        super.init(column: column, initialValue: 0)
    }
    
    override public func databaseReadFromValue(value: String) {
        update(value.bridge().integerValue)
    }
    
    override public func databaseValueForWriting() -> String {
        return String(value())
    }
}

extension Int {
    init(intProperty: IntProperty) {
        self.init(intProperty.value())
    }
}

public protocol Model {
    init()
    static var table: String { get }
    static var columns: [String] { get }
    var map: [String:BaseProperty] { get }
}
