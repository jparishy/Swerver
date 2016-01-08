//
//  JSONTests.swift
//  Swerver
//
//  Created by Julius Parishy on 12/12/15.
//  Copyright © 2015 Julius Parishy. All rights reserved.
//

import XCTest
import Swerver
import Foundation

class JSONTests: XCTestCase, XCTestCaseProvider {
	func testJSONWriting() {
		do {
			//

			let emptyArray: [JSONEncodable] = []
			let emptyArrayStr = try str(emptyArray)
			XCTAssertEqual(emptyArrayStr, "[]", "Should output empty JSON array")

			//

			let emptyArrayOfInts: [Int] = []
			let emptyArrayOfIntsStr = try str(emptyArrayOfInts)
			XCTAssertEqual(emptyArrayOfIntsStr, "[]", "Should output empty JSON array")

			//

			let emptyDict: [String:JSONEncodable] = [:]
			let emptyDictStr = try str(emptyDict)
			XCTAssertEqual(emptyDictStr, "{}", "Should output empty JSON dict")

			//

			let emptyDictOfInts: [String:Int] = [:]
			let emptyDictOfIntsStr = try str(emptyDictOfInts)
			XCTAssertEqual(emptyDictOfIntsStr, "{}", "Should output empty JSON dict")

			//

			let mixedDict: [String:JSONEncodable] = [
				"test" : "hi",
				"ok" : 3,
				"cool" : false
			]

			let mixedDictStr = try str(mixedDict)
			XCTAssertEqual(mixedDictStr, "{\"cool\":false,\"ok\":3,\"test\":\"hi\"}", "Should have valid mixed json string")

			//

			let nestedDict = [
				"outer" : [
					"inner" : 3
				]
			]

			let nestedDictStr = try str(nestedDict)
			XCTAssertEqual(nestedDictStr, "{\"outer\":{\"inner\":3}}")

			// 

			let arrayOfDicts: [[String:JSONEncodable]] = [
				["test" : "ok"],
				["sup"  : 42]
			]

			let arrayOfDictsStr = try str(arrayOfDicts)
			XCTAssertEqual(arrayOfDictsStr, "[{\"test\":\"ok\"},{\"sup\":42}]")

			// 

			let dictOfDicts: [String:[String:JSONEncodable]] = [
				"a" : ["test" : "ok"],
				"b" : ["sup"  : 42]
			]

			let dictOfDictsStr = try str(dictOfDicts)
			XCTAssertEqual(dictOfDictsStr, "{\"a\":{\"test\":\"ok\"},\"b\":{\"sup\":42}}")

			//

			let dictWithNull: [String:JSONEncodable] = [
				"key" : NSNull()
			]

			let dictWithNullStr = try str(dictWithNull)
			XCTAssertEqual(dictWithNullStr, "{\"key\":null}")

		} catch {
			XCTFail("None of these should throw")
		}
	}
}

extension JSONTests {
	var allTests: [(String, () -> Void)] {
		return [
			("testJSONWriting", testJSONWriting)
		]
	}
}


// MARK - Specialized convenience funcs

func str(obj: [JSONEncodable]) throws -> String {
	let data = try NSJSONSerialization.swerver_dataWithJSONObject(obj, options: NSJSONWritingOptions(rawValue: 0))
	return NSString(bytes: data.bytes, length: data.length, encoding: NSUTF8StringEncoding)!.bridge()
}

func str<T: JSONEncodable>(obj: [T]) throws -> String {
	let data = try NSJSONSerialization.swerver_dataWithJSONObject(obj, options: NSJSONWritingOptions(rawValue: 0))
	return NSString(bytes: data.bytes, length: data.length, encoding: NSUTF8StringEncoding)!.bridge()
}

func str(obj: [String:JSONEncodable]) throws -> String {
	let data = try NSJSONSerialization.swerver_dataWithJSONObject(obj, options: NSJSONWritingOptions(rawValue: 0))
	return NSString(bytes: data.bytes, length: data.length, encoding: NSUTF8StringEncoding)!.bridge()
}

func str<T : JSONEncodable>(obj: [String:T]) throws -> String {
	let data = try NSJSONSerialization.swerver_dataWithJSONObject(obj, options: NSJSONWritingOptions(rawValue: 0))
	return NSString(bytes: data.bytes, length: data.length, encoding: NSUTF8StringEncoding)!.bridge()
}