//
//  SessionsController.swift
//  Swerver
//
//  Created by Julius Parishy on 12/17/15.
//  Copyright © 2015 Julius Parishy. All rights reserved.
//

import Foundation

class SessionsController : Controller {
    override func index(request: Request, parameters: Parameters, session inSession: Session, transaction t: Transaction) throws -> ControllerResponse {
        return view(SessionIndexView(username: inSession["username"] as? String))
    }
    
    override func create(request: Request, parameters: Parameters, session inSession: Session, transaction t: Transaction) throws -> ControllerResponse {
        var session = Session()
        if let username = parameters["username"] as? String {
            session.update("username", username)
        }
        
        return try redirect(to: "/sessions", session: session)
    }
    
    func signOut(request: Request, parameters: Parameters, session inSession: Session, transaction t: Transaction) throws /* UserError, InternalServerError */ -> ControllerResponse {
        
        var session = Session()
        session.update("username", nil)
        
        return try redirect(to: "/sessions", session: session)
    }
}