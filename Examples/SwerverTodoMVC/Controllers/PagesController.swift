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
        return view(PageHomeView())
    }
    
    func about(request: Request, parameters: Parameters, session inSession: Session, transaction t: Transaction) throws -> ControllerResponse {
        return view(PageAboutView())
    }
    
    func contributing(request: Request, parameters: Parameters, session inSession: Session, transaction t: Transaction) throws /* UserError, InternalServerError */ -> ControllerResponse {
        return view(PageContributingView())
    }
}