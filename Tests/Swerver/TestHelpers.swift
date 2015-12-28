import XCTest
import Foundation
import libuv
import libpq
import CryptoSwift
@testable import Swerver

let TestApplicationSecret = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"

class TestApplication : Application {
	let databaseConfiguration: DatabaseConfiguration? = nil
	let applicationSecret = TestApplicationSecret
	let publicDirectory = ""

	func resource<T : Controller>(name: String, namespace: String? = nil, additionRoutes: (T) -> ([ResourceSubroute])) -> Resource {
        let controller = T()
        controller.application = self
        
        let routes = additionRoutes(controller)
        return Resource(name: name, controller: controller, subroutes: ResourceSubroute.CRUD(routes), namespace: namespace)
    }
}
