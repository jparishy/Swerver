import XCTest
import Foundation
import libuv
import libpq
import CryptoSwift
@testable import Swerver

let BadSecret = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"

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
			let app = Application(applicationSecret: BadSecret, databaseConfiguration: db, publicDirectory: "")
			
			let c = TestController(application: app)
			c.resource = Resource(name: "test", controller: c)

			let test: (NSData, ((Request, Parameters, Session, Transaction) -> Void)) throws -> Void = {
				(data: NSData, assertions: ((Request, Parameters, Session, Transaction) -> Void)) throws -> Void in

				c.handleIndex = {
					(r: Request, p: Parameters, s: Session, t: Transaction) throws -> ControllerResponse in
					
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
			let db = DatabaseConfiguration(username: "jp", password: "password", databaseName: "notes")
			let app = Application(applicationSecret: BadSecret, databaseConfiguration: db, publicDirectory: "")
			
			let c = TestController(application: app)
			c.resource = Resource(name: "test", controller: c)

			c.handleIndex = {
				(r: Request, p: Parameters, s: Session, t: Transaction) throws -> ControllerResponse in

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
				(r: Request, p: Parameters, s: Session, t: Transaction) throws -> ControllerResponse in

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
}

extension ControllerTests {
	var allTests : [(String, () -> Void)] {
		return [
			("testParameters", testParameters),
			("testCookies", testCookies)
		]
	}
}
