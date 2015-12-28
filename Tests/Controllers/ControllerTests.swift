import XCTest
import Foundation
import libuv
import libpq
import CryptoSwift
@testable import Swerver

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

class ControllerTests : XCTestCase, XCTestCaseProvider {
	func testParameters() {

		do {
			let app = TestApplication()
			
			let c = TestController(application: app)
			c.resource = Resource(name: "test", controller: c)

			let test: (NSData, ((Request, Parameters, Session, Transaction?) -> Void)) throws -> Void = {
				(data: NSData, assertions: ((Request, Parameters, Session, Transaction?) -> Void)) throws -> Void in

				c.handleIndex = {
					(r: Request, p: Parameters, s: Session, t: Transaction?) throws -> ControllerResponse in
					
					assertions(r, p, s, t)

					return ControllerResponse(.Ok)
				}

				if let request = HTTP11(rawRequest: data).request() {
					try c.apply(request)
				} else {
					XCTFail("Could not make request from data")
				}
			}

			try test(MakeHTTPRequest("GET", path: "/test", headers: ["Content-Type":"application/x-www-form-urlencoded"], body: "test=working")) {
				r, p, s, t in

				XCTAssertNil(p["some_invalid_key"], "should be nil")

				if let t = p["test"] as? String {
					XCTAssertEqual(t, "working", "Should have the parameter passed in the request")
				} else {
					XCTFail("Missing parameter")
				}
			}

			try test(MakeHTTPRequest("GET", path: "/test", headers: ["Content-Type":"application/json"], body: "{\"test\":\"valid json\"}")) {
				r, p, s, t in

				if let t = p["test"] as? String {
					XCTAssertEqual(t, "valid json", "Should have the parameter passed in the request")
				} else {
					XCTFail("Missing parameter")
				}
			}
		}
		catch {
			XCTFail("Should not throw")
		}
	}

	func testCookies() {
		do {
			let app = TestApplication()

			let c = TestController(application: app)
			c.resource = Resource(name: "test", controller: c)

			c.handleIndex = {
				(r: Request, p: Parameters, s: Session, t: Transaction?) throws -> ControllerResponse in

				var out = Session()
				out.update("key", "value")

				return ControllerResponse(.Ok, session: out)
			}

			let setData = MakeHTTPRequest("GET", path: "/test", headers: [:], body: "")
			var cookie: String? = nil
			if let request = HTTP11(rawRequest: setData).request() {
				let response = try c.apply(request)

				if let setCookie = response.headers["Set-Cookie"] {
					if let part = setCookie.swerver_componentsSeparatedByString(";").first {
						cookie = part
					}
				} else {
					XCTFail("Should have Set-Cookie in response headers")
				}

			} else {
				XCTFail("Could not make request from data")
			}

			if cookie == nil {
				XCTFail("Cookie is nil")
			}

			c.handleIndex = {
				(r: Request, p: Parameters, s: Session, t: Transaction?) throws -> ControllerResponse in

				if let value = s["key"] as? String {
					XCTAssertEqual(value, "value", "session should have the same value set from the previous request")
				} else {
					XCTFail("Missing value for key in session")
				}

				return ControllerResponse(.Ok)
			}

			if let cookie = cookie {
				let getData = MakeHTTPRequest("GET", path: "/test", headers: ["Cookie":cookie], body: "")
				if let request = HTTP11(rawRequest: getData).request() {
					try c.apply(request)
				} else {
					XCTFail("Could not make request from data")
				}
			}

		} catch {
			XCTFail("Should not throw")
		}
	}

	func testAllCRUDActions() {
		let app = TestApplication()

		let c = TestController(application: app)
		c.resource = Resource(name: "test", controller: c)

		c.handleIndex = {
			(r: Request, p: Parameters, s: Session, t: Transaction?) throws -> ControllerResponse in
			return ControllerResponse(.Ok)
		}

		c.handleShow = {
			(r: Request, p: Parameters, s: Session, t: Transaction?) throws -> ControllerResponse in
			return ControllerResponse(.Ok)
		}

		c.handleNew = {
			(r: Request, p: Parameters, s: Session, t: Transaction?) throws -> ControllerResponse in
			return ControllerResponse(.Ok)
		}

		c.handleCreate = {
			(r: Request, p: Parameters, s: Session, t: Transaction?) throws -> ControllerResponse in
			return ControllerResponse(.Ok)
		}

		c.handleUpdate = {
			(r: Request, p: Parameters, s: Session, t: Transaction?) throws -> ControllerResponse in
			return ControllerResponse(.Ok)
		}

		c.handleDelete = {
			(r: Request, p: Parameters, s: Session, t: Transaction?) throws -> ControllerResponse in
			return ControllerResponse(.Ok)
		}

		let datas = [
			MakeHTTPRequest("GET", path: "/test", headers: [:], body: ""),
			MakeHTTPRequest("GET", path: "/test/42", headers: [:], body: ""),
			MakeHTTPRequest("GET", path: "/test/new", headers: [:], body: ""),
			MakeHTTPRequest("POST", path: "/test", headers: [:], body: ""),
			MakeHTTPRequest("PUT", path: "/test/42", headers: [:], body: ""),
			MakeHTTPRequest("DELETE", path: "/test/42", headers: [:], body: ""),
		]

		for data in datas {
			do {
				if let request = HTTP11(rawRequest: data).request() {
					let response = try c.apply(request)
					XCTAssertEqual(response.statusCode.integerCode, StatusCode.Ok.integerCode, "Should have gotten a 200 response code")
				} else {
					XCTFail("Could not make request")
				}
			} catch {
				XCTFail("Should have been able to route the request")
			}
		}
	}
}

extension ControllerTests {
	var allTests : [(String, () -> Void)] {
		return [
			("testParameters", testParameters),
			("testCookies", testCookies),
			("testAllCRUDActions", testAllCRUDActions)
		]
	}
}
