import XCTest
import Foundation
import libuv
import libpq
import CryptoSwift
@testable import Swerver

class TestModel : Model {
	let id = IntProperty(column: "id")
	let b = BoolProperty(column: "a_bool")
	let i = IntProperty(column: "an_int")
	let s = StringProperty(column: "a_string")

    required init() {}

    override class var table: String {
    	return "tests"
    }

    override class var columns: [String] {
    	return [
    		"a_bool",
    		"an_int",
    		"a_string"
    	]
    }

    override class var primaryKey: String {
    	return "id"
	}

   	override var properties: [BaseProperty] {
    	return [ id, b, i, s]
    }
}

class TestTransaction : Transaction {
    func command(command: String) throws -> QueryResult? { return nil }
    func query(command: String) throws -> QueryResult { return [] }
    func exec(command: String) throws -> COpaquePointer { return COpaquePointer() }

    func begin() throws { }
    func commit() {}

    func register(m: Model) { }
}

class ModelQueryTests : XCTestCase, XCTestCaseProvider {
	func testInsertQuery() {
		let m = TestModel()
		m.b.update(true)
		m.i.update(42)
		m.s.update("jp")

		let mq = try! ModelQuery<TestModel>(transaction: TestTransaction())
		let query = try! mq.insertQuery(m)

		XCTAssertEqual(query, "INSERT INTO tests(an_int, a_string, a_bool) VALUES (42, \'jp\', true) RETURNING id")
	}

	func testUpdateQuery() {
		let m = TestModel()
		m.id.update(7)
		m.b.update(true)
		m.i.update(42)
		m.s.update("jp")

		let mq = try! ModelQuery<TestModel>(transaction: TestTransaction())
		let query = try! mq.updateQuery(m)
		
		XCTAssertEqual(query, "UPDATE tests SET id = 7, an_int = 42, a_string = 'jp', a_bool = true WHERE id = 7;")
	}
}

extension ModelQueryTests {
	var allTests : [(String, () -> Void)] {
		return [
			("testUpdateQuery", testUpdateQuery),
		]
	}
}
