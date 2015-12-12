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
    Resource(name:  "notes",           controller: NotesController())
])

do {
    let db = try Database(databaseName: "notes", username: "jp")
    try db.transaction {
        t in
        let query = ModelQuery<Note>(transaction: t)
        let results = try query.all()
        if let result = results.first {
            let str = result.text.value() + "|"
            result.text.update(str)
            print(result)
        }
    }
} catch DatabaseError.OpenFailure(let status, let message) {
    print("Failed to open database (statusCode=\(status)):\n\(message)")
} catch DatabaseError.TransactionFailure(let status, let message) {
    print("Transaction failed (statusCode=\(status)):\n\(message)")
}

let server = HTTPServer<HTTP11>(port: 80, router: router)
server.start()
