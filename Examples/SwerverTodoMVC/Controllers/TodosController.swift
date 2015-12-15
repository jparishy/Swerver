//
//  TodosController.swift
//  Swerver
//
//  Created by Julius Parishy on 12/11/15.
//  Copyright © 2015 Julius Parishy. All rights reserved.
//

import Foundation

class TodosController : Controller {
    override func index(request: Request, parameters: Parameters, transaction t: Transaction) throws -> Response {
        let query = ModelQuery<Todo>(transaction: t)
        let results = try query.all()
        
        return try RespondTo(request) {
            (format: ResponseFormat) throws -> Response in
            switch format {
            case .HTML:
                return (.Ok, [:], nil)
            case .JSON:
                let dicts = try JSONDictionariesFromModels(results)
                return try Ok.JSON(dicts)
            }
        }
    }
    
    override func create(request: Request, parameters: Parameters, transaction t: Transaction) throws -> Response {
        if let JSON = try parse(request) as? NSDictionary {
            let query = ModelQuery<Todo>(transaction: t)
            
            let model: Todo = try ModelFromJSONDictionary(JSON)
            let created = try query.insert(model)
            
            let dict = try JSONDictionaryFromModel(created)
            return try Ok.JSON(dict)
        } else {
            return (.InvalidRequest, [:], nil)
        }
    }
    
    override func update(request: Request, parameters: Parameters, transaction t: Transaction) throws -> Response {
        if let JSON = try parse(request) as? NSDictionary {
            let query = ModelQuery<Todo>(transaction: t)
            
            let model: Todo = try ModelFromJSONDictionary(JSON)
            let updated = try query.update(model)
            
            let dict = try JSONDictionaryFromModel(updated)
            return try Ok.JSON(dict)
        } else {
            return (.InvalidRequest, [:], nil)
        }
    }
    
    override func delete(request: Request, parameters: Parameters, transaction t: Transaction) throws -> Response {
        if let id = parameters["id"] as? NSNumber {
            let query = ModelQuery<Todo>(transaction: t)
            try query.delete(id)
            
            return (.Ok, [:], nil)
        } else {
            let query = ModelQuery<Todo>(transaction: t)
            let toDelete = try query.findWhere(["completed":true])
            
            for m in toDelete {
                try query.delete(NSNumber(integer: Int(m.id)))
            }
            
            return (.Ok, [:], nil)
        }
    }
}
