import XCTest
import Foundation
import libuv
import libpq
import CryptoSwift
@testable import Swerver

class TestController : Controller {
	var handleIndex: ControllerRequestHandler? = nil
	override func index(request: Request, parameters: Parameters, session inSession: Session, transaction t: Transaction) throws /* UserError, InternalServerError */ -> ControllerResponse {
	    if let index = handleIndex {
	    	return try index(request: request, parameters: parameters, session: inSession, transaction: t)
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

class ControllerTests : XCTestCase, XCTestCaseProvider {
	func testParameters() {

		do {
			let db = DatabaseConfiguration(username: "jp", password: "password", databaseName: "notes")
			let app = Application(applicationSecret: "blah", databaseConfiguration: db, publicDirectory: "")
			
			let c = TestController(application: app)
			c.resource = Resource(name: "test", controller: c)

			c.handleIndex = {
				(r: Request, p: Parameters, s: Session, t: Transaction) throws -> ControllerResponse in
				 
				if let t = p["test"] as? String {
					XCTAssertEqual(t, "working", "Should have the parameter passed in the request")
				} else {
					XCTFail("Missing parameter")
				}

				return ControllerResponse(.Ok)
			}

			let data = MakeHTTPRequest("GET", path: "/test", headers: ["Content-Type":"application/x-www-form-urlencoded"], body: "test=working")
			let rawRequest = HTTP11(rawRequest: data)
			if let request = rawRequest.request() {
				try c.apply(request)
			} else {
				XCTFail("Coult not make request.")
			}
		}
		catch {
			XCTFail("Should not throw")
		}
	}
}

extension ControllerTests {
	var allTests : [(String, () -> Void)] {
		return [
			("testParameters", testParameters)
		]
	}
}
