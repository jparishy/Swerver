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

public enum ModelQueryError: ErrorType {
    case TransactionRequired
    case PrimaryKeyRequired
    case InvalidPrimaryKey
}

public class ModelQuery<T : Model> {

    public let transaction: Transaction
    
    public init(transaction: Transaction?) throws {
        if let transaction = transaction {
            self.transaction = transaction
        } else {
            throw ModelQueryError.TransactionRequired
        }
    }
    
    internal func insertQuery(m: T) throws -> String {
        var query = "INSERT INTO \(T.table)("
        
        var index = 0
        for (k,_) in ModelsMap(m.properties) {
            if k == T.primaryKey {
                index += 1
                continue
            }
            
            query += "\(k)"
            
            if index < (ModelsMap(m.properties).count - 1) {
                query += ", "
            } else {
                query += ")"
            }
            
            index += 1
        }
        
        query += " VALUES ("
        
        index = 0
        for (k,v) in ModelsMap(m.properties) {
            if k == T.primaryKey {
                index += 1
                continue
            }
            
            let vv = try v.databaseValueForWriting()
            query += vv
            
            if index < (ModelsMap(m.properties).count - 1) {
                query += ", "
            } else {
                query += ")"
            }
            
            index += 1
        }
        
        query += " RETURNING \(T.primaryKey)"

        return query
    }

    public func insert(m: T) throws -> T {
        let query = try insertQuery(m)
        let queryResults = try transaction.command(query)

        if let first = queryResults?.first, id = first[T.primaryKey] {
            try ModelsMap(m.properties)[T.primaryKey]?.databaseReadFromValue(id)
        }
        
        return m
    }
    
    internal func updateQuery(m: T) throws -> String {
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
                
                index += 1
            }
            
            query += "WHERE \(m.dynamicType.primaryKey) = \(primaryKeyValue);"
            return query
        } else {
            throw ModelQueryError.PrimaryKeyRequired
        }
    }

    public func update(m: T) throws -> T {
        let query = try updateQuery(m)
        try transaction.command(query)

        return m
    }
    
    internal func deleteQuery(primaryKeyValue: Int) throws -> String {
        return "DELETE FROM \(T.table) WHERE \(T.primaryKey) = \(primaryKeyValue);"
    }

    public func delete(primaryKeyValue: Int) throws {
        let query = try deleteQuery(primaryKeyValue)
        try transaction.command(query)
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
    
    public func findWhere(params: [String:Any]) throws -> [T] {
        
        var query = "SELECT * FROM \(T.table)"
        
        if params.count > 0 {
            query += " WHERE("
        
            var index = 0
            for (k, v) in params {
                
                query += k
                query += " = "
                
                if v is String {
                    query += "'\(v)'"
                } else if let v = v as? Bool {
                    query += (v ? "true" : "false")
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
