//
//  JSONTests.swift
//  Swerver
//
//  Created by Julius Parishy on 12/12/15.
//  Copyright © 2015 Julius Parishy. All rights reserved.
//

import XCTest

class JSONTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func test_swerver_isValidJSONObject() {
        XCTAssertFalse(NSJSONSerialization.swerver_isValidJSONObject("json fragment"))
        XCTAssertFalse(NSJSONSerialization.swerver_isValidJSONObject(3))
        
        XCTAssertTrue(NSJSONSerialization.swerver_isValidJSONObject([]))
        XCTAssertTrue(NSJSONSerialization.swerver_isValidJSONObject([:]))
        
        let expectTrue = {
            (str: String, obj: AnyObject) -> Void in
            XCTAssertTrue(NSJSONSerialization.swerver_isValidJSONObject(obj), "Expected: \(str)")
        }
        
        let expectFalse = {
            (str: String, obj: AnyObject) -> Void in
            XCTAssertFalse(NSJSONSerialization.swerver_isValidJSONObject(obj), "Expected: \(str)")
        }
        
        expectTrue("valid dict", [
            "test" : 30
        ])
        
        expectFalse("invalid dict key", [
            42 : 30
        ])
        
        expectTrue("valid embedded dict", [
            "validKey" : [
                "validEmbeddedKey" : "validObject"
            ]
        ])
        
        expectTrue("valid embedded array", [
            "validKey" : [ "valid1", "valid2" ]
        ])
        
        expectFalse("invalid embedded dict", [
            "validKey" : [
                3 : "invalidEmbeddedObject"
            ]
        ])
        
        expectFalse("invalid embedded dict due to invalid value for key", [
            "validKey" : [
                "validEmbddedKey" : NSDate()
            ]
        ])
        
        expectFalse("invalid embedded array ", [
            "validKey" : [
                "validEmbddedKey" : [ NSDate() ]
            ]
        ])

        expectTrue("valid doubly nested dict ", [
            "validKey" : [
                "validEmbddedKey" : [
                    "embedded2" : "hi",
                ]
            ]
        ])

        expectFalse("invalid doubly nested dict ", [
            "validKey" : [
                "validEmbddedKey" : [
                    "embedded2" : NSDate(),
                ]
            ]
        ])
    }
    
    func test_swerver_JSONObjectWithData() {
        let makeData = {
            (str: String) -> NSData? in
            if let bytes = str.cStringUsingEncoding(NSUTF8StringEncoding) {
                return NSData(bytes: bytes, length: bytes.count)
            } else {
                XCTFail("Bad String")
                return nil
            }
        }
        
        let expectTrue = {
            (message: String, JSONString: String, expectedObject: AnyObject) in
            if let data = makeData(JSONString) {
                do {
                    let result = try NSJSONSerialization.swerver_JSONObjectWithData(data, options: NSJSONReadingOptions(rawValue: 0))
                    XCTAssertEqual(result as? NSObject, expectedObject as? NSObject, message)
                } catch JSONError.UnexpectedToken(let m, let loc) {
                    XCTFail("\(m) — at loc \(loc)")
                } catch let error as NSError {
                    XCTFail("NSJSONSerialization threw: \(error.localizedDescription)")
                }
            } else {
                XCTFail("Bad String")
            }
        }
        
        let expectThrows = {
            (message: String, JSONString: String) in
            if let data = makeData(JSONString) {
                do {
                    try NSJSONSerialization.swerver_JSONObjectWithData(data, options: NSJSONReadingOptions(rawValue: 0))
                    XCTFail("\(message)\nExpected throw on:\n\(JSONString)")
                } catch {
                    XCTAssert(true)
                }
            } else {
                XCTFail("Bad String")
            }
        }
        
        expectTrue("valid single entry dict", "{\"key\":\"value\"}", [
            "key" : "value"
        ])

        expectTrue("valid multi entry dict", "{\"key1\":\"value1\",\"key2\":\"value2\",\"key3\":\"value3\"}", [
            "key1" : "value1",
            "key2" : "value2",
            "key3" : "value3"
        ])
        
        expectTrue("valid single element array", "[42]", [
            42
        ])

        expectTrue("valid multi element array", "[42,43,44]", [
            42, 43, 44
        ])
        
        expectTrue("valid nested dict", "{\"key1\":\"value1\",\"nested\":{\"key2\":\"value2\",\"key3\":\"value3\"}}", [
            "key1" : "value1",
            "nested" : [
                "key2" : "value2",
                "key3" : "value3"
            ]
        ])
        
        expectTrue("valid array of dicts", "[{\"key1\":\"value1\"},{\"key2\":\"value2\"},{\"key3\":\"value3\"}]", [
            [ "key1" : "value1" ],
            [ "key2" : "value2" ],
            [ "key3" : "value3" ],
        ])
        
        expectTrue("valid array of dicts with first dict value being dict", "[{\"key1\": {\"value1\":[1,2,3]}},{\"key2\":\"value2\"},{\"key3\":\"value3\"}]", [
            [ "key1" : [ "value1" : [ 1, 2, 3] ] ],
            [ "key2" : "value2" ],
            [ "key3" : "value3" ],
        ])
        
        expectThrows("missing coma", "{\"key1\":\"value1\" \"key2\":\"value2\",\"key3\":\"value3\"}")
        expectThrows("missing closing curly brace", "{\"key1\":\"value1\",\"key2\":\"value2\",\"key3\":\"value3\"")
        
        expectThrows("unescaped quote in string key", "{\"ke\"y1\":\"value1\",\"key2\":\"value2\",\"key3\":\"value3\"")
        expectThrows("unescaped quote in string value", "{\"key1\":\"val\"ue1\",\"key2\":\"value2\",\"key3\":\"value3\"")
        
        expectTrue("escaped quote in string key", "{\"k\\\"ey\":\"value\"}", [
            "k\"ey" : "value"
        ])
    
        expectTrue("escaped quote in string value", "{\"key\":\"this is a \\\"quoted string\\\"\"}", [
            "key" : "this is a \"quoted string\""
        ])
    }
}
