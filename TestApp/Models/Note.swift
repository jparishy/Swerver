//
//  Note.swift
//  Swerver
//
//  Created by Julius Parishy on 12/11/15.
//  Copyright © 2015 Julius Parishy. All rights reserved.
//

import Foundation

class Note {
    required init() {
    }
    
    internal var transaction: Transaction? = nil
    
    let id = IntProperty(column: "id")
    let text = StringProperty(column: "text")
}

extension Note : CustomStringConvertible {
    var description: String {
        return "<Note: id=\(id); text=\"\(text)\";>"
    }
}

extension Note : Model {
    static var table: String {
        return "notes"
    }
    
    static var columns: [String] {
        return [
            "id",
            "text"
        ]
    }
    
    static var primaryKey: String {
        return "id"
    }
    
    var map: [String : BaseProperty] {
        return [
            "id"   : self.id,
            "text" : self.text
        ]
    }
}
