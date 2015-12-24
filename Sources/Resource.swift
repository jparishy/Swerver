//
//  Resource.swift
//  Swerver
//
//  Created by Julius Parishy on 12/11/15.
//  Copyright © 2015 Julius Parishy. All rights reserved.
//

import Foundation

public typealias Parameters = [String:AnyObject]

public enum ResourceAction {
    case Index
    case Show
    case New
    case Create
    case Update
    case Delete
    case NamespaceIdentity
    case Custom(handler: ControllerRequestHandler)
}

public struct ResourceSubroute {
    let method: HTTPMethod
    let action: ResourceAction
    let path: String?
    
    let namespace: String?
    let resourceName: String
    
    init(method: HTTPMethod, action: ResourceAction) {
        self.init(method: method, path: nil, action: action)
    }
    
    init(method: HTTPMethod, path: String?, action: ResourceAction, resourceName: String = "", namespace: String? = nil) {
        self.method = method
        self.action = action
        self.path = path
        self.resourceName = resourceName
        self.namespace = namespace
    }
    
    static func CRUD(extras: [ResourceSubroute] = []) -> [ResourceSubroute] {
        var all = extras
        
        all += [
            ResourceSubroute(method: .GET,    path: "new", action: .New),
            ResourceSubroute(method: .GET,    path: nil,   action: .Index),
            ResourceSubroute(method: .POST,   path: nil,   action: .Create),
            ResourceSubroute(method: .GET,    path: ":id", action: .Show),
            ResourceSubroute(method: .PUT,    path: ":id", action: .Update),
            ResourceSubroute(method: .DELETE, path: ":id", action: .Delete),
        ]
        
        return all
    }
    
    private var fullPath: String {
        if let path: NSString = self.path?.bridge() where path.hasPrefix("/") {
            return path.bridge()
        } else {
            var fullPath = "/"
            if let ns = namespace {
                fullPath += "\(ns)/"
            }
            
            fullPath += "\(resourceName)"
            
            if let path = path {
                fullPath += "/\(path)"
            }
            
            return fullPath
        }
    }
    
    private func matches(path inPath: String, method: HTTPMethod) -> Bool {
        return matchForParameters(path: inPath, method: method).0
    }
    
    public func parameters(request: Request) -> Parameters? {
        return matchForParameters(path: request.path, method: request.method).1
    }
    
    private func matchForParameters(path inPath: String, method: HTTPMethod) -> (Bool, Parameters?) {
        
        let path: String
        if inPath.hasSuffix("/") && inPath != "/" {
            path = inPath.substringWithRange(inPath.startIndex..<inPath.endIndex.advancedBy(-1))
        } else {
            path = inPath
        }
        
        let fullPath = self.fullPath
        
        let requestComponents = path.componentsSeparatedByString("/")
        let selfComponents = fullPath.componentsSeparatedByString("/")
        
        if method != self.method {
            return (false, nil)
        }
        
        if requestComponents.count != selfComponents.count {
            return (false, nil)
        }
        
        var parameters = Parameters()
        
        for (r, s) in zip(requestComponents, selfComponents) {
            
            if s.hasPrefix(":") {
                
                let key = s.substringFromIndex(s.startIndex.advancedBy(1))
                let value = r
                parameters[key] = value
                
            } else {
                if r != s {
                    return (false, nil)
                }
            }
        }
        
        return (true, parameters)
    }
}

public class Resource : Route {
    
    let name: String
    let namespace: String?
    let controller: Controller
    let subroutes: [ResourceSubroute]
    
    convenience init(name: String, controller: Controller, namespace: String? = nil) {
        self.init(name: name, controller: controller, subroutes: ResourceSubroute.CRUD(), namespace: namespace)
    }
    
    init(name: String, controller: Controller, subroutes: [ResourceSubroute], namespace: String? = nil) {
        self.name = name
        self.namespace = namespace
        
        self.controller = controller
        
        self.subroutes = subroutes.map {
            sr in
            return ResourceSubroute(method: sr.method, path: sr.path, action: sr.action, resourceName: name, namespace: namespace)
        }
        
        let matchFunction = {
            (route: Route, request: Request) -> Bool in
            if let r = route as? Resource {
                
                // Namespace Identity
                if let namespace = r.namespace where request.path == namespace {
                    return true
                }
                
                if r.subrouteForRequest(request) != nil {
                    return true
                }
            }
            
            return false
        }
        
        super.init(routeProvider: controller, matchFunction: matchFunction)
        
        controller.resource = self
    }
    
    internal func subrouteForRequest(request: Request) -> ResourceSubroute? {
        
        for subroute in subroutes {
            if subroute.matches(path: request.path, method: request.method) {
                return subroute
            }
        }
        
        return nil
    }
}
