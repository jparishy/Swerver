//
//  Controller.swift
//  Swerver
//
//  Created by Julius Parishy on 12/11/15.
//  Copyright © 2015 Julius Parishy. All rights reserved.
//

import Foundation

class Controller : RouteProvider {

    internal var resource: Resource?
    
    func apply(request: Request) throws /* UserError, InternalServerError */ -> Response {
        if let subroute = resource?.subrouteForRequest(request) {
            let parameters = subroute.parameters()
            switch subroute.action {
            case .Index:
                return try self.index(request, parameters: parameters)
            case .Create:
                return try self.create(request, parameters: parameters)
            case .Update:
                return try self.update(request, parameters: parameters)
            case .Delete:
                return try self.delete(request, parameters: parameters)
            case .NamespaceIdentity:
                return (.Ok, [:], nil)
            default:
                throw UserError.Unimplemented
            }
        } else {
            throw UserError.Unimplemented
        }
    }
    
    func index(request: Request, parameters: Parameters) throws /* UserError, InternalServerError */ -> Response {
        throw UserError.Unimplemented
    }

    func create(request: Request, parameters: Parameters) throws /* UserError, InternalServerError */ -> Response {
        throw UserError.Unimplemented
    }
    
    func update(request: Request, parameters: Parameters) throws /* UserError, InternalServerError */ -> Response {
        throw UserError.Unimplemented
    }

    func delete(request: Request, parameters: Parameters) throws /* UserError, InternalServerError */ -> Response {
        throw UserError.Unimplemented
    }
    
    func parse(request: Request) throws -> AnyObject? {
        if let body = request.requestBody {
            
            do {
                let JSON = try NSJSONSerialization.swerver_JSONObjectWithData(body, options: NSJSONReadingOptions(rawValue: 0))
                return JSON
            } catch {
                return nil
            }
        } else {
            return nil
        }
    }
    
    func connect() throws -> Database {
        return try Database(databaseName: "notes", username: "jp", password: "password")
    }
}
