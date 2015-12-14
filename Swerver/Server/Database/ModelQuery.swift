//
//  ModelQuery.swift
//  Swerver
//
//  Created by Julius Parishy on 12/11/15.
//  Copyright © 2015 Julius Parishy. All rights reserved.
//

import Foundation

class ModelQuery<T : Model> {
    let transaction: Transaction
    
    init(transaction: Transaction) {
        self.transaction = transaction
    }
    
    func insert(m: T) throws -> T {
        var query = "INSERT INTO \(T.table)("
        
        var index = 0
        for (k,_) in m.map {
            if k == T.primaryKey {
                index++
                continue
            }
            
            query += "\(k)"
            
            if index < (m.map.count - 1) {
                query += ", "
            } else {
                query += ")"
            }
            
            index++
        }
        
        query += " VALUES ("
        
        index = 0
        for (k,v) in m.map {
            if k == T.primaryKey {
                index++
                continue
            }
            
            let vv = try v.databaseValueForWriting()
            query += vv
            
            if index < (m.map.count - 1) {
                query += ", "
            } else {
                query += ")"
            }
            
            index++
        }
        
        query += " RETURNING \(T.primaryKey)"
        
        let queryResults = try transaction.command(query)
        if let first = queryResults?.first, id = first[T.primaryKey] {
            try m.map[T.primaryKey]?.databaseReadFromValue(id)
        }
        
        return m
    }
    
    func update(m: T) throws -> T {
        let primaryKey = m.dynamicType.primaryKey
        if let primaryKeyValue = try m.map[primaryKey]?.databaseValueForWriting() {
            var query = "UPDATE \(m.dynamicType.table) SET "
            
            var index = 0
            for (k,v) in m.map {
                let vs = try v.databaseValueForWriting()
                query += "\(k) = \(vs)"
                
                if index < (m.map.count - 1) {
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
    
    func delete(primaryKeyValue: AnyObject) throws {
        if let pk = primaryKeyValue as? NSNumber {
            let query = "DELETE FROM \(T.table) WHERE \(T.primaryKey) = \(pk.integerValue);"
            try transaction.command(query)
        }
    }
    
    func all() throws -> [T] {
        
        var results = [T]()
        
        let rows = try self.transaction.query("SELECT * FROM \(T.table) ORDER BY \(T.primaryKey)")
        for row in rows {
        
            let m = T()
            for (k,v) in row {
                if let p = m.map[k] {
                    try p.databaseReadFromValue(v)
                }
            }
            
            transaction.register(m)
            
            results.append(m)
        }
        
        return results
    }
}