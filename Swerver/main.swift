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

class HelloProvider : RouteProvider {
    func apply(request: Request) throws -> Response {
        return  (.Ok, ["Content-Type":"text/html"], ResponseData.Str("<html><body><h1>Hello World! This server is running Swift!</h1></body></html>"))
    }
}

class ErrorProvider : RouteProvider {
    func apply(request: Request) throws -> Response {
        throw InternalServerError.Generic
    }
}

let router = Router(routes: [
    PathRoute(path: "/hello_world", routeProvider: HelloProvider()),
    PathRoute(path: "/throw",       routeProvider: ErrorProvider()),
    PathRoute(path: "/",            routeProvider: Redirect("/hello_world")),
    Resource(name: "notes",         controller: NotesController())
])

let server = HTTPServer<HTTP11>(port: 8080, router: router)
server.start()
