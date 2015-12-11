//
//  SwiftNonsense.swift
//  Swerver
//
//  Created by Julius Parishy on 12/11/15.
//  Copyright © 2015 Julius Parishy. All rights reserved.
//

import Foundation

extension String {

#if os(OSX)
    func bridge() -> NSString {
        return self as NSString
    }
#endif

    // I have no idea how this is really implemented so we'll fake it
    func swerver_cStringUsingEncoding(encoding: NSStringEncoding) -> [UInt8] {
        return [UInt8](self.utf8)
    }
}

extension NSString {

#if os(OSX)
    func bridge() -> String {
        return self as String
    }
#endif

    func swerver_cStringUsingEncoding(encoding: NSStringEncoding) -> [UInt8] {
        return self.bridge().swerver_cStringUsingEncoding(encoding)
    }
    
    func swerver_lengthOfBytesUsingEncoding(encoding: NSStringEncoding) -> Int {
        return swerver_cStringUsingEncoding(encoding).count
    }

    // This is a fake ass version that only supports one char, but that's OK for our use case
    func swerver_componentsSeparatedByString(string: NSString) -> [String] {
        let separator = UInt8(string.characterAtIndex(0))
        
        var components: [String] = []
        var currentComponent = ""
        
        let chars = swerver_cStringUsingEncoding(NSUTF8StringEncoding)
        let len = chars.count
        for i in 0..<len {
            if chars[i] == separator {
                components.append(currentComponent)
                currentComponent = ""
            } else {
                currentComponent += String(Character(UnicodeScalar(chars[i])))
            }
        }
        
        if currentComponent.swerver_cStringUsingEncoding(NSUTF8StringEncoding).count > 0 {
            components.append(currentComponent)
        }
        
        return components
    }
    // Another naive approach
    func swerver_stringByTrimmingCharactersInSet(set: NSCharacterSet) -> String {
        var outString = ""
        let chars = swerver_cStringUsingEncoding(NSUTF8StringEncoding)
        
        let len = chars.count
        for i in 0..<len {
            if set.characterIsMember(unichar(chars[i])) == false {
                outString.append(Character(UnicodeScalar(chars[i])))
            }
        }
        
        return outString
    }
}
