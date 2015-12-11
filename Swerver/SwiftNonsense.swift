//
//  SwiftNonsense.swift
//  Swerver
//
//  Created by Julius Parishy on 12/11/15.
//  Copyright © 2015 Julius Parishy. All rights reserved.
//

import Foundation

extension String {
    // I have no idea how this is really implemented so we'll fake it
    func swerver_cStringUsingEncoding(encoding: NSStringEncoding) -> [UInt8] {
        return [UInt8](self.utf8)
    }
}

extension NSString {
    func swerver_cStringUsingEncoding(encoding: NSStringEncoding) -> [UInt8] {
        return (self as String).swerver_cStringUsingEncoding(encoding)
    }
}