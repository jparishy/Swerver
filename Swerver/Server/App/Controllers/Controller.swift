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
        do {
            if let subroute = resource?.subrouteForRequest(request) {
                
                let db = try connect()
                let parameters = subroute.parameters()
                
                do {
                    return try db.transaction {
                        t in
                        
                        let response: Response
                        switch subroute.action {
                        case .Index:
                            response = try self.index(request, parameters: parameters, transaction: t)
                            break
                        case .Create:
                            response = try self.create(request, parameters: parameters, transaction: t)
                            break
                        case .Update:
                            response = try self.update(request, parameters: parameters, transaction: t)
                            break
                        case .Delete:
                            response = try self.delete(request, parameters: parameters, transaction: t)
                            break
                        case .NamespaceIdentity:
                            response = (.Ok, [:], nil)
                            break
                        default:
                            throw UserError.Unimplemented
                        }
                        
                        t.commit()
                        
                        return response
                    }
                } catch {
                    return (.InternalServerError, [:], nil)
                }
            } else {
                throw UserError.Unimplemented
            }
        } catch JSONError.UnexpectedToken(let message, _) {
            print("*** [ERROR]: \(message)")
            return (.InternalServerError, [:], nil)
        } catch JSONError.InvalidInput {
            print("*** [ERROR]: Invalid JSON Input")
            return (.InternalServerError, [:], nil)
        } catch DatabaseError.TransactionFailure(_, let message) {
            print("*** [ERROR]: \(message)")
            return (.InternalServerError, [:], nil)
        } catch DatabaseError.OpenFailure(_, let message) {
            print("*** [ERROR]: \(message)")
            return (.InternalServerError, [:], nil)
        } catch {
            print("*** [ERROR] Unknown Internal Service Error")
            return (.InternalServerError, [:], nil)
        }
    }
    
    func index(request: Request, parameters: Parameters, transaction t: Transaction) throws /* UserError, InternalServerError */ -> Response {
        throw UserError.Unimplemented
    }

    func create(request: Request, parameters: Parameters, transaction t: Transaction) throws /* UserError, InternalServerError */ -> Response {
        throw UserError.Unimplemented
    }
    
    func update(request: Request, parameters: Parameters, transaction t: Transaction) throws /* UserError, InternalServerError */ -> Response {
        throw UserError.Unimplemented
    }

    func delete(request: Request, parameters: Parameters, transaction t: Transaction) throws /* UserError, InternalServerError */ -> Response {
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
