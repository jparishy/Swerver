//
//  main.swift
//  Swerver
//
//  Created by Julius Parishy on 12/4/15.
//  Copyright © 2015 Julius Parishy. All rights reserved.
//

import Foundation

#if os(Linux)
    import Glibc
#endif

Application.start {
    app in
    
    let router = Router([
        // General
        PathRoute.root("/index.html"),
        PublicFiles(directory: app.publicDirectory),
        
        // Resources
        Resource(name: "todos", controller: TodosController(application: app), namespace: "api"),
        Resource(name: "users", controller: UsersController(application: app)),
        
        // Using Application#resource allows for customizing the subroutes
        app.resource("sessions") {
            (c: SessionsController) -> [ResourceSubroute] in
            return [
                ResourceSubroute(method: "GET",  action: .Custom(path: "/sessions/sign_in",  handler: c.index)),
                ResourceSubroute(method: "GET",  action: .Custom(path: "/sessions/sign_out", handler: c.signOut))
            ]
        }
    ])
    
    return (port: 8080, router: router)
}
