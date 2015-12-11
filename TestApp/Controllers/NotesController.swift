//
//  NotesController.swift
//  Swerver
//
//  Created by Julius Parishy on 12/11/15.
//  Copyright © 2015 Julius Parishy. All rights reserved.
//

import Foundation

class NotesController : Controller {
    override func index(request: Request) throws -> Response {
        return (.Ok, [:], ResponseData.Str("Listing notes."))
    }
}
