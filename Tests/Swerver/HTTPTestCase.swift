import XCTest
import libuv
import libpq
import Swerver 

class HTTPTestCase : XCTestCase, XCTestCaseProvider {
	func testHeaders() {
		let router = Router([])
		let server = HTTPServer<HTTP11>(port: 8080, router: router)
		print(server)
	}
}

extension HTTPTestCase {
	var allTests : [(String, () -> Void)] {
		return [
			("testHeaders", testHeaders)
		]
	}
}
