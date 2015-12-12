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
    
    func insert(m: T) throws {
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
            
            query += "\(try v.databaseValueForWriting())"
            
            if index < (m.map.count - 1) {
                query += ", "
            } else {
                query += ")"
            }
            
            index++
        }
        
        try transaction.command(query)
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