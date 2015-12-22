//
//  TodosController.swift
//  Swerver
//
//  Created by Julius Parishy on 12/11/15.
//  Copyright © 2015 Julius Parishy. All rights reserved.
//

import Foundation

class TodosController : Controller {
    override func index(request: Request, parameters: Parameters, session: Session, transaction t: Transaction) throws -> ControllerResponse {
        let query = ModelQuery<Todo>(transaction: t)
        let results = try query.all()
        
        return try respond(request) {
            responseFormat in
            switch responseFormat {
            case .JSON:
                return try Ok.JSON(results)
            default:
                return nil
            }
        }
    }
    
    override func create(request: Request, parameters: Parameters, session: Session, transaction t: Transaction) throws -> ControllerResponse {
        let query = ModelQuery<Todo>(transaction: t)
        
        let model: Todo = try ModelFromJSONDictionary(parameters)
        let created = try query.insert(model)
        
        return try ControllerResponse(Ok.JSON(created))
    }
    
    override func update(request: Request, parameters: Parameters, session: Session, transaction t: Transaction) throws -> ControllerResponse {
        let query = ModelQuery<Todo>(transaction: t)
        
        let model: Todo = try ModelFromJSONDictionary(parameters)
        let updated = try query.update(model)
        
        return try ControllerResponse(Ok.JSON(updated))
    }
    
    override func delete(request: Request, parameters: Parameters, session: Session, transaction t: Transaction) throws -> ControllerResponse {
        if let id = parameters["id"] as? NSNumber {
            let query = ModelQuery<Todo>(transaction: t)
            try query.delete(id)
            
            return builtin(.Ok)
        } else {
            let query = ModelQuery<Todo>(transaction: t)
            let toDelete = try query.findWhere(["completed": JSONBool(bool: true)])
            
            for m in toDelete {
                try query.delete(NSNumber(integer: Int(m.id)))
            }
            
            return builtin(.Ok)
        }
    }
}
