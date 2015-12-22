//
//  Application.swift
//  Swerver
//
//  Created by Julius Parishy on 12/17/15.
//  Copyright © 2015 Julius Parishy. All rights reserved.
//

import Foundation



public class Application {

    static let DefaultPublicDirectory = "./Public/"
    
    private var server: HTTPServer<HTTP11>?
    
    private var _publicDirectory: String
    
    public var publicDirectory: String {
        return _publicDirectory
    }
    
    init(publicDirectory dir: String) {
        _publicDirectory = dir
    }
    
    private func start(port: Int, router: Router) {
        server?.start()
    }
    
    static func start(publicDirectory: String = Application.DefaultPublicDirectory, configuration: (Application) -> (port: Int, router: Router)) {
        
        let app = Application(publicDirectory: publicDirectory)
        
        let (port, router) = configuration(app)
        app.server = HTTPServer<HTTP11>(port: port, router: router)
        
        app.start(port, router: router)
    }
    
    func resource<T : Controller>(name: String, additionRoutes: (T) -> ([ResourceSubroute])) -> Resource {
        let controller = T()
        controller.application = self
        
        let routes = additionRoutes(controller)
        return Resource(name: name, controller: controller, subroutes: ResourceSubroute.CRUD(routes))
    }
}
