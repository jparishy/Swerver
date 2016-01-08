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

class TestController : Controller {
	var handleIndex: ControllerRequestHandler? = nil
	var handleShow: ControllerRequestHandler? = nil
	var handleNew: ControllerRequestHandler? = nil
	var handleCreate: ControllerRequestHandler? = nil
	var handleUpdate: ControllerRequestHandler? = nil
	var handleDelete: ControllerRequestHandler? = nil
	var handleNamespaceIdentity: ControllerRequestHandler? = nil

	override func index(request: Request, parameters: Parameters, session inSession: Session, transaction t: Transaction?) throws -> ControllerResponse {
	    if let index = handleIndex {
	    	return try index(request: request, parameters: parameters, session: inSession, transaction: t)
	    } else {
	    	throw UserError.Unimplemented
	    }
	}

	override func show(request: Request, parameters: Parameters, session inSession: Session, transaction t: Transaction?) throws -> ControllerResponse {
	    if let show = handleShow {
	    	return try show(request: request, parameters: parameters, session: inSession, transaction: t)
	    } else {
	    	throw UserError.Unimplemented
	    }
	}

	override func new(request: Request, parameters: Parameters, session inSession: Session, transaction t: Transaction?) throws -> ControllerResponse {
	    if let new = handleNew {
	    	return try new(request: request, parameters: parameters, session: inSession, transaction: t)
	    } else {
	    	throw UserError.Unimplemented
	    }
	}

	override func create(request: Request, parameters: Parameters, session inSession: Session, transaction t: Transaction?) throws -> ControllerResponse {
	    if let create = handleCreate {
	    	return try create(request: request, parameters: parameters, session: inSession, transaction: t)
	    } else {
	    	throw UserError.Unimplemented
	    }
	}

	override func update(request: Request, parameters: Parameters, session inSession: Session, transaction t: Transaction?) throws -> ControllerResponse {
	    if let update = handleUpdate {
	    	return try update(request: request, parameters: parameters, session: inSession, transaction: t)
	    } else {
	    	throw UserError.Unimplemented
	    }
	}

	override func delete(request: Request, parameters: Parameters, session inSession: Session, transaction t: Transaction?) throws -> ControllerResponse {
	    if let delete = handleDelete {
	    	return try delete(request: request, parameters: parameters, session: inSession, transaction: t)
	    } else {
	    	throw UserError.Unimplemented
	    }
	}
}

func MakeHTTPRequest(method: String, path: String, headers: Headers, body: String) -> NSData {
	var r = ""
	r += "\(method) \(path) HTTP/1.1\r\n"
	for (k,v) in headers {
		r += "\(k): \(v)\r\n"
	}
	r += "\r\n"
	r += body

	let bytes = r.bridge().swerver_cStringUsingEncoding(NSUTF8StringEncoding)
	return NSData(bytes: bytes, length: bytes.count)
}