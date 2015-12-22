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

let ApplicationSecret: String = NSProcessInfo.processInfo().environment["SWERVER_ORG_SECRET"]!
assert(ApplicationSecret.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) == 32, "Invalid Application Secret. You should set a 32-character secret in the Debug Scheme or in your shell environment with the name: SWERVER_ORG_SECRET")

Application.start(ApplicationSecret, databaseConfiguration: DatabaseConfiguration(username: "jp", password: "password", databaseName: "notes")) {
    app in
    
    let router = Router([
        // Resources
        Resource(name: "users", controller: UsersController(application: app)),
        
        // Using Application#resource allows for customizing the subroutes
        app.resource("pages") {
            (c: PagesController) -> [ResourceSubroute] in
            return [
                ResourceSubroute(method: .GET, path: "/",  action: .Custom(handler: c.home)),
                ResourceSubroute(method: .GET, path: "/about", action: .Custom(handler: c.about)),
                ResourceSubroute(method: .GET, path: "/contributing", action: .Custom(handler: c.contributing))
            ]
        },
        
        app.resource("sessions") {
            (c: SessionsController) -> [ResourceSubroute] in
            return [
                ResourceSubroute(method: .GET, path: "/sign_in",  action: .Custom(handler: c.index)),
                ResourceSubroute(method: .GET, path: "/sign_out", action: .Custom(handler: c.signOut))
            ]
        },
        
        app.resource("todos", namespace: "api") {
            (c: TodosController) -> [ResourceSubroute] in
            return [
                ResourceSubroute(method: .DELETE, action: .Custom(handler: c.delete)) // Angular app also expects `DELETE /api/todos` to work
            ]
        },
        
        // General
        PublicFiles(directory: app.publicDirectory),
    ])
    
    return (port: 8080, router: router)
}
