//
//  StringTests.swift
//  Swerver
//
//  Created by Julius Parishy on 12/13/15.
//  Copyright © 2015 Julius Parishy. All rights reserved.
//

import XCTest
import Swerver
import Foundation

class StringTests: XCTestCase {

    func test_swerver_stringByReplacingOccurrencesOfStringWithString() {
        XCTAssertEqual("Hello".swerver_stringByReplacingOccurrencesOfString("ello", withString: "i"), "Hi")
        XCTAssertEqual("Hel\\\tlo".swerver_stringByReplacingOccurrencesOfString("\\\t", withString: ""), "Hello")
        
        XCTAssertEqual("hi hi hi hi ".swerver_stringByReplacingOccurrencesOfString(" ", withString: ""), "hihihihi")
        XCTAssertEqual("hi hi hi hi  ".swerver_stringByReplacingOccurrencesOfString("  ", withString: ""), "hi hi hi hi")
        XCTAssertEqual("  hi hi hi hi  ".swerver_stringByReplacingOccurrencesOfString("  ", withString: ""), "hi hi hi hi")
        XCTAssertEqual("  hi hi hi hi".swerver_stringByReplacingOccurrencesOfString("  ", withString: ""), "hi hi hi hi")
        
        XCTAssertEqual("hi hi hi hi".swerver_stringByReplacingOccurrencesOfString("i", withString: ""), "h h h h")
        XCTAssertEqual("help help help help".swerver_stringByReplacingOccurrencesOfString("elp", withString: "i"), "hi hi hi hi")
        
        XCTAssertEqual("hi".swerver_stringByReplacingOccurrencesOfString("longer", withString: "nothing"), "hi")
        XCTAssertEqual("   hi".swerver_stringByReplacingOccurrencesOfString("longer", withString: "nothing"), "   hi")
    }
    
    func test_swerver_stringByTrimmingCharactersInSet() {
        XCTAssertEqual("  hi   \n\n".swerver_stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()), "hi")
        XCTAssertEqual("  \nhi".swerver_stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()), "hi")
        XCTAssertEqual("hi   \n\n".swerver_stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()), "hi")
        XCTAssertEqual("\r\n".swerver_stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()), "")
        XCTAssertEqual("fullyvalid".swerver_stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()), "fullyvalid")
        XCTAssertEqual("".swerver_stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()), "")
        XCTAssertEqual("a".swerver_stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()), "a")
    }
}

extension StringTests {
	var allTests: [(String, () -> Void)] {
		return [
			("test_swerver_stringByReplacingOccurrencesOfStringWithString", test_swerver_stringByReplacingOccurrencesOfStringWithString),
			("test_swerver_stringByTrimmingCharactersInSet", test_swerver_stringByTrimmingCharactersInSet)
		]
	}
}
