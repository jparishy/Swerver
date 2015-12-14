# Swerver
### [WIP] Swift HTTP Server/MVC Framework

![Example Screenshot](http://i.imgur.com/MncDaVp.jpg)

Hiya. Swerver is an HTTP server and MVC framework for web applications in Swift.
It is currently very much a work in progress, but it's coming along nicely so I wanted to put some information in the readme in case anyone wants to play along from home.

Swerver's TCP handling is based on libuv's C API. An HTTP Server is built upon that, and routing lives above there. I try to make the directory structure reflect what parts of the code are doing what.

# Hello World
This is what a hello world looks like in Swerver.

```
import Foundation

class HelloProvider : RouteProvider {
    func apply(request: Request) throws -> Response {
        return  (.Ok, ["Content-Type":"text/html"], ResponseData("<html><body><h1>Hello World! This server is running Swift!</h1></body></html>"))
    }
}

let router = Router(routes: [
    PathRoute(path: "/", routeProvider: HelloProvider()),
])

let server = HTTPServer<HTTP11>(port: 8080, router: router)
server.start()

```

And a more complicated example the test app inside of the Swerver codebase.

```
import Foundation

class NotesController : Controller {
    override func index(request: Request) throws -> Response {
        do {
            let db = try connect()
            return try db.transaction {
                t in
                
                let query = ModelQuery<Note>(transaction: t)
                let results = try query.all()
                
                t.commit()
                
                do {
                    return try RespondTo(request) {
                        (format: ResponseFormat) throws -> Response in
                        switch format {
                        case .HTML:
                            return (.Ok, [:], nil)
                        case .JSON:
                            let dicts = try JSONDictionariesFromModels(results)
                            let data = try NSJSONSerialization.swerver_dataWithJSONObject(dicts, options: NSJSONWritingOptions(rawValue: 0))
                            return (.Ok, ["Content-Type":"application/json"], ResponseData.Data(data))
                        }
                    }
                } catch {
                    return (.InternalServerError, [:], nil)
                }
            }
        } catch {
            return (.InternalServerError, [:], nil)
        }
    }
    
    override func create(request: Request) throws -> Response {
        if let JSON = try parse(request) as? NSDictionary {
            do {
                let db = try connect()
                return try db.transaction {
                    t in
                    
                    let query = ModelQuery<Note>(transaction: t)

                    let model: Note = try ModelFromJSONDictionary(JSON)
                    try query.insert(model)
                    
                    t.commit()
                    
                    return (.Ok, [:], nil)
                }
            } catch {
                return (.InternalServerError, [:], nil)
            }
        } else {
            return (.InvalidRequest, [:], nil)
        }
    }
}

class HelloProvider : RouteProvider {
    func apply(request: Request) throws -> Response {
        return  (.Ok, ["Content-Type":"text/html"], ResponseData("<html><body><h1>Hello World! This server is running Swift!</h1></body></html>"))
    }
}

let router = Router(routes: [
    PathRoute(path: "/",            routeProvider: Redirect("/hello_world")),
    PathRoute(path: "/hello_world", routeProvider: HelloProvider()),
    Resource(name:  "notes",           controller: NotesController()),
    PublicFiles(prefix: "public")
])

let server = HTTPServer<HTTP11>(port: 8080, router: router)
server.start()

```

#### Goals:
1. Provide the Infrastructure for a Swift based HTTP server with built-in routing capabilities and dispatching to Controllers to handle Models and render Views.
2. Provide a light wrapper around PostgreSQL for access to a Database and a sort-kinda ORM for going back and forth between your in-app models and what's stored in the DB.
3. Proper support for CSRF Protection and Session state for users.
4. Type Safety for Web Development. Yes, Swerver is more verbose than Ruby on Rails. Deal with it. You won't have to write unit tests to confirm your types are correct — the compiler will do that for you.
5. Simple Testing Framework. So far what's out there isn't doing it for me.
6. OS X and Linux support. In its current state, Swerver supports both platforms but definitely runs better on OS X. I've implemented really crappy version of some missing Foundation APIs for Linux; this will improve eventually.

----

#### Getting Started

##### OS X
_Prerequisites: homebrew_

1. Install libuv:

    `brew install libuv`
    
2. Install [PostgreSQL.app](http://postgresapp.com/) and setup a new user & database. You'll need to change your settings in `main.swift` to reflect your role, password, and database name.
3. Open the Xcode Project and use that. The included build script ***does not*** support OS X.
4. Build & Run and have some fun.

##### Ubuntu 15.10
_Note: I tried to get Swift to work on 14.x but failed. You may be smarter than me though_

1. Install the Swift binaries. There are great instructions over at [Swift.org](https://swift.org/getting-started/). I put the swift root folder in `~/code/` so my PATH looks like `/home/jp/code/swift-2.2-SNAPSHOT-2015-12-01-b-ubuntu15.10/usr/bin:$PATH`; your mileage may vary.
2. Ubuntu comes with libuv so you're good there. But you need to install the PostgreSQL libraries:

    `sudo apt-get install libpq-dev`
    
3. While in the Swerver root folder, invoke the build script with `./build.sh`. I tried to make the build scirpt as generic as I could, but you may have some configuration differences on your system so if it fails open it up and see if any of the folders look off.
4. If the build script succeeds, it places the app binary in the current directory with the name `app` so to run it just type `./app`.

----

#### So What's Even Working?

Not that much! Swerver has support for:

1. Basic Exact Path Routing
2. Basic Exact Path Resource Routing to Controllers
3. Model support without Foreign Keys
4. Responding to requests for JSON or HTML
5. ...And that's pretty much it. But it's a start!

So what's next you ask?

My personal list of things to work on are:

1. Adding more means for quering and foreign key references to Models.
2. Regex matching for routes.
3. Support for Nginx
4. Proper view templating support. I'm thinking I'll base this off of how Elixir does it. Very cool stuff going on over there.
5. Migration support for the DB tables. Probably based off Octo because I do really like what the Elixir folks are doing. You can probably see that in how I implemented the Model protocol.

----

##### What you can do?

Whatever you like! I'm totally down to accept PRs. I only ask that you make sure your code runs on both OS X and Linux with Swift 2.2. Soon I will setup a CI server and put together a test suite and this will be easier but in the mean time please manually test.


Ok cool. This is gonna be awesome. If you need me, you can reach me via email:
julius@jaymobile.io (<- That's my company, if you need an app developed lemme know ;))
or Twitter: @jparishy

Cheers from NJ!
