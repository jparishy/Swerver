//
//  Resource.swift
//  Swerver
//
//  Created by Julius Parishy on 12/11/15.
//  Copyright © 2015 Julius Parishy. All rights reserved.
//

import Foundation

enum ResourceAction {
    case Index
    case Create
    case Update
    case Delete
    case Custom(path: String)
}

struct ResourceSubroute {
    let method: String
    let action: ResourceAction
    
    static func CRUD() -> [ResourceSubroute] {
        return [
            ResourceSubroute(method: "GET",    action: .Index),
            ResourceSubroute(method: "POST",   action: .Create),
            ResourceSubroute(method: "PUT",    action: .Update),
            ResourceSubroute(method: "DELETE", action: .Delete)
        ]
    }
    
    private func matches(pathComponents: [String], method: String) -> Bool {

        let path: String
        
        if pathComponents.count == 0 {
            path = ""
        } else {
            if let first = pathComponents.first {
                if first == "/" {
                    path = ""
                } else {
                    path = first
                }
            } else {
                path = ""
            }
        }
        
        switch action {
        case .Index:
            return (path == "") && (method == "GET")
            
        case .Create:
            return (path == "") && (method == "POST")
            
        case .Update:
            return (path == "") && (method == "PUT")
            
        case .Delete:
            return (path == "") && (method == "DELETE")
            
        case .Custom:
            return false
        }
    }
}

class Resource : Route {
    
    let name: String
    let controller: Controller
    let subroutes: [ResourceSubroute]
    
    convenience init(name: String, controller: Controller) {
        self.init(name: name, controller: controller, subroutes: ResourceSubroute.CRUD())
        controller.resource = self
    }
    
    init(name: String, controller: Controller, subroutes: [ResourceSubroute]) {
        self.name = name
        self.controller = controller
        self.subroutes = subroutes
        
        let matchFunction = {
            (route: Route, request: Request) -> Bool in
            if let r = route as? Resource {
                if r.subrouteForRequest(request) != nil {
                    return true
                }
            }
            
            return false
        }
        
        super.init(routeProvider: controller, matchFunction: matchFunction)
    }
    
    internal func subrouteForRequest(request: Request) -> ResourceSubroute? {
        if let URL = NSURL(string: request.path), allComponents = URL.pathComponents {
            let components: [String]
            if let first = allComponents.first where first == "/" {
                components = [String](allComponents.dropFirst(1))
                } else {
                components = allComponents
            }
            
            if components.count == 0 {
                return nil
            }
            
            if let name = components.first where name == self.name {
                let rest = [String](components.dropFirst(1))
                for subroute in subroutes {
                    if subroute.matches(rest, method: request.method) {
                        return subroute
                    }
                }
            }
        }
    
        return nil
    }
}
