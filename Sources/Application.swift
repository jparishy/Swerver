//
//  Application.swift
//  Swerver
//
//  Created by Julius Parishy on 12/17/15.
//  Copyright © 2015 Julius Parishy. All rights reserved.
//

import Foundation

public struct DatabaseConfiguration {
    let username: String
    let password: String
    let databaseName: String
}

public class Application {

    static let DefaultPublicDirectory = "./Public/"
    
    private var server: HTTPServer<HTTP11>?
    
    public let databaseConfiguration: DatabaseConfiguration
    
    private var _applicationSecret: String
    public var applicationSecret: String {
        return _applicationSecret
    }
    
    private var _publicDirectory: String
    public var publicDirectory: String {
        return _publicDirectory
    }
    
    public init(applicationSecret secret: String, databaseConfiguration configuration: DatabaseConfiguration, publicDirectory dir: String) {
        _applicationSecret = secret
        _publicDirectory = dir
        
        databaseConfiguration = configuration
    }
    
    private func start(port: Int, router: Router) {
        server?.start()
    }
    
    public static func start(applicationSecret: String, databaseConfiguration: DatabaseConfiguration, publicDirectory: String = Application.DefaultPublicDirectory, configuration: (Application) -> (port: Int, router: Router)) {
        
        let app = Application(applicationSecret: applicationSecret, databaseConfiguration: databaseConfiguration, publicDirectory: publicDirectory)
        
        let (port, router) = configuration(app)
        app.server = HTTPServer<HTTP11>(port: port, router: router)
        
        app.start(port, router: router)
    }
    
    public func resource<T : Controller>(name: String, namespace: String? = nil, additionRoutes: (T) -> ([ResourceSubroute])) -> Resource {
        let controller = T()
        controller.application = self
        
        let routes = additionRoutes(controller)
        return Resource(name: name, controller: controller, subroutes: ResourceSubroute.CRUD(routes), namespace: namespace)
    }
}
