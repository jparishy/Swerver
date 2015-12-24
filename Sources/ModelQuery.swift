//
//  ModelQuery.swift
//  Swerver
//
//  Created by Julius Parishy on 12/11/15.
//  Copyright © 2015 Julius Parishy. All rights reserved.
//

import Foundation

#if os(Linux)
import Glibc
#endif

public class ModelQuery<T : Model> {
    public let transaction: Transaction
    
    public init(transaction: Transaction) {
        self.transaction = transaction
    }
    
    public func insert(m: T) throws -> T {
        var query = "INSERT INTO \(T.table)("
        
        var index = 0
        for (k,_) in ModelsMap(m.properties) {
            if k == T.primaryKey {
                index++
                continue
            }
            
            query += "\(k)"
            
            if index < (ModelsMap(m.properties).count - 1) {
                query += ", "
            } else {
                query += ")"
            }
            
            index++
        }
        
        query += " VALUES ("
        
        index = 0
        for (k,v) in ModelsMap(m.properties) {
            if k == T.primaryKey {
                index++
                continue
            }
            
            let vv = try v.databaseValueForWriting()
            query += vv
            
            if index < (ModelsMap(m.properties).count - 1) {
                query += ", "
            } else {
                query += ")"
            }
            
            index++
        }
        
        query += " RETURNING \(T.primaryKey)"
        
        let queryResults = try transaction.command(query)
        if let first = queryResults?.first, id = first[T.primaryKey] {
            try ModelsMap(m.properties)[T.primaryKey]?.databaseReadFromValue(id)
        }
        
        return m
    }
    
    public func update(m: T) throws -> T {
        let primaryKey = m.dynamicType.primaryKey
        if let primaryKeyValue = try ModelsMap(m.properties)[primaryKey]?.databaseValueForWriting() {
            var query = "UPDATE \(m.dynamicType.table) SET "
            
            var index = 0
            for (k,v) in ModelsMap(m.properties) {
                let vs = try v.databaseValueForWriting()
                query += "\(k) = \(vs)"
                
                if index < (ModelsMap(m.properties).count - 1) {
                    query += ", "
                } else {
                    query += " "
                }
                
                index++
            }
            
            query += "WHERE \(m.dynamicType.primaryKey) = \(primaryKeyValue);"
            try transaction.command(query)
        } else {
            print("WARNING: \(m) is dirty but does not have a valid primary key and cannot be updated.")
        }
        
        return m
    }
    
    public func delete(primaryKeyValue: AnyObject) throws {
        if let pk = primaryKeyValue as? NSNumber {
            let query = "DELETE FROM \(T.table) WHERE \(T.primaryKey) = \(pk.integerValue);"
            try transaction.command(query)
        }
    }
    
    public func deleteAll() throws {
        let query = "DELETE FROM \(T.table);"
        try transaction.command(query)
    }
    
    public func all() throws -> [T] {
        
        var results = [T]()
        
        let rows = try self.transaction.query("SELECT * FROM \(T.table) ORDER BY \(T.primaryKey)")
        for row in rows {
            
            let m = T()
            for (k,v) in row {
                if let p = ModelsMap(m.properties)[k] {
                    try p.databaseReadFromValue(v)
                }
            }
            
            transaction.register(m)
            
            results.append(m)
        }
        
        return results
    }
    
    public func findWhere(params: [String:AnyObject]) throws -> [T] {
        
        var query = "SELECT * FROM \(T.table)"
        
        if params.count > 0 {
            query += " WHERE("
        
            var index = 0
            for (k, v) in params {
                if v is Bool && !(v is Int) {
                    print("*** [ERROR] Use JSONBool in place of Bool for serialization and query purposes")
                    exit(1)
                }
                
                query += k
                query += " = "
                
                if v is String {
                    query += "'\(v)'"
                } else if let v = v as? JSONBool {
                    query += (v.value ? "true" : "false")
                } else {
                    query += "\(v)"
                }
                
                if index < params.count - 1 {
                    query += ", "
                }
                
                index += 1
            }
            
            query += ") "
        }
        
        query += "ORDER BY \(T.primaryKey);"
        
        var results = [T]()
        
        let rows = try self.transaction.query(query)
        for row in rows {
        
            let m = T()
            for (k,v) in row {
                if let p = ModelsMap(m.properties)[k] {
                    try p.databaseReadFromValue(v)
                }
            }
            
            transaction.register(m)
            
            results.append(m)
        }
        
        return results
    }
}
