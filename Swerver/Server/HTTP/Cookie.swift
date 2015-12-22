//
//  Cookie.swift
//  Swerver
//
//  Created by Julius Parishy on 12/17/15.
//  Copyright © 2015 Julius Parishy. All rights reserved.
//

import Foundation

struct Cookie {
    let name: String
    let value: String
    
    init?(string: String) {
        let parts = string.bridge().swerver_componentsSeparatedByString("=")
        
        if parts.count == 2 {
            name = parts[0]
            value = parts[1]
        } else {
            return nil
        }
    }
    
    static func parse(string: String) -> [Cookie] {
        let cookies: [Cookie?] = string.bridge().swerver_componentsSeparatedByString(";").map {
            str in
            let cleaned = str.bridge().swerver_stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            return Cookie(string: cleaned)
        }
        
        var out = [Cookie]()
        for c in cookies {
            if let c = c {
                out.append(c)
            }
        }
        
        return out
    }
}

extension Cookie : CustomStringConvertible {
    var description: String {
        return "<Cookie: name=\"\(name)\" value=\"\(value)\">"
    }
}
