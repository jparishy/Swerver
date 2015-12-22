//
//  UsersController.swift
//  Swerver
//
//  Created by Julius Parishy on 12/17/15.
//  Copyright © 2015 Julius Parishy. All rights reserved.
//

import Foundation

class UsersController : Controller {
    override func index(request: Request, parameters: Parameters, session: Session, transaction t: Transaction) throws -> ControllerResponse {
        return view(UserIndexView())
    }
    
    override func create(request: Request, parameters: Parameters, session: Session, transaction t: Transaction) throws -> ControllerResponse {
        return builtin(.Ok)
    }
    
    override func show(request: Request, parameters: Parameters, session: Session, transaction t: Transaction) throws -> ControllerResponse {
        if let param = parameters["id"] as? String, userID = Int(param) {
            return view(UserShowView(userID: userID))
        } else {
            return builtin(.NotFound)
        }
    }
}
