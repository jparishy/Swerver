//
//  View.swift
//  Swerver
//
//  Created by Julius Parishy on 12/17/15.
//  Copyright © 2015 Julius Parishy. All rights reserved.
//

import Foundation

class View : Template {
    let renderFunc: (Renderer) -> ()
    
    init(renderFunc: (Renderer) -> ()) {
        self.renderFunc = renderFunc
        super.init()
    }
    
    func render() -> String {
        return Template.render(renderFunc)
    }
    
    static func response(view: View, statusCode: StatusCode = .Ok, headers: Headers = [:]) -> Response {
        
        var allHeaders = headers
        if allHeaders["Content-Type"] == nil {
            allHeaders["Content-Type"] = "text/html"
        }
        
        return Response(statusCode, headers: allHeaders, responseData: ResponseData(view.render()))
    }
}

