//
//  View.swift
//  Swerver
//
//  Created by Julius Parishy on 12/17/15.
//  Copyright © 2015 Julius Parishy. All rights reserved.
//

import Foundation

public class View : Template {
    public let renderFunc: (Renderer) -> ()
    
    public init(renderFunc: (Renderer) -> ()) {
        self.renderFunc = renderFunc
        super.init()
    }
    
    public func render(flash: [String:String] = [:]) -> String {
        return Template.render(flash, renderFunc: renderFunc)
    }
    
    public static func response(view: View, statusCode: StatusCode = .Ok, headers: Headers = [:], flash: [String:String] = [:]) -> Response {
        
        var allHeaders = headers
        if allHeaders["Content-Type"] == nil {
            allHeaders["Content-Type"] = "text/html"
        }
        
        return Response(statusCode, headers: allHeaders, responseData: ResponseData(view.render(flash)))
    }
}

