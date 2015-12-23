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
    
        let mq = ModelQuery<User>(transaction: t)
        
        let user: User?
        if let userID = inSession["user_id"] as? Int, u = try mq.findWhere(["id":userID]).first {
            user = u
        } else {
            user = nil
        }
        
        return view(SessionIndexView(user: user))
    }
    
    override func create(request: Request, parameters: Parameters, session inSession: Session, transaction t: Transaction) throws -> ControllerResponse {
        
        let mq = ModelQuery<User>(transaction: t)
        if let email = parameters["email"] as? String, let password = parameters["password"] as? String {
            
            if let user = try mq.findWhere(["email":email]).first where user.authenticateWithPassword(password) {
                var session = Session()
                session.update("user_id", user.id.value())
                return try redirect(to: "/sessions", session: session)
            } else {
                return view(SessionIndexView(user: nil), flash: ["error":"Invalid Email or Password"])
            }
        } else {
            return view(SessionIndexView(user: nil), flash: ["error":"Missing Email or Password"])
        }
    }
    
    func signOut(request: Request, parameters: Parameters, session inSession: Session, transaction t: Transaction) throws /* UserError, InternalServerError */ -> ControllerResponse {
        
        var session = Session()
        session.update("user_id", nil)
        
        return try redirect(to: "/sessions", session: session)
    }
}