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
    
    func all() throws -> [T] {
        
        var results = [T]()
        
        let rows = try self.transaction.query("SELECT * FROM \(T.table)")
        for row in rows {
        
            let m = T()
            for (k,v) in row {
                if let p = m.map[k] {
                    try p.databaseReadFromValue(v)
                }
            }
            
            results.append(m)
        }
        
        return results
    }
}