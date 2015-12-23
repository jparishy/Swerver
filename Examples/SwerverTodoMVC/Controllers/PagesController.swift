//
//  PagesController.swift
//  Swerver
//
//  Created by Julius Parishy on 12/22/15.
//  Copyright © 2015 Julius Parishy. All rights reserved.
//

import Foundation

class PagesController : Controller {
    func home(request: Request, parameters: Parameters, session inSession: Session, transaction t: Transaction) throws -> ControllerResponse {
        
        let mq = ModelQuery<User>(transaction: t)
        
        let user: User?
        if let userID = inSession["user_id"] as? Int, u = try mq.findWhere(["id":userID]).first {
            user = u
        } else {
            user = nil
        }
        
        return view(PageHomeView(user: user))
    }
    
    func about(request: Request, parameters: Parameters, session inSession: Session, transaction t: Transaction) throws -> ControllerResponse {
        return view(PageAboutView())
    }
    
    func contributing(request: Request, parameters: Parameters, session inSession: Session, transaction t: Transaction) throws /* UserError, InternalServerError */ -> ControllerResponse {
        return view(PageContributingView())
    }
}