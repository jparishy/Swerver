//
//  Note.swift
//  Swerver
//
//  Created by Julius Parishy on 12/11/15.
//  Copyright © 2015 Julius Parishy. All rights reserved.
//

import Foundation

class Todo {
    required init() {
    }
    
    internal var transaction: Transaction? = nil
    
    let id = IntProperty(column: "id")
    
    let title = StringProperty(column: "title")
    let completed = BoolProperty(column: "completed")
}

extension Todo : CustomStringConvertible {
    var description: String {
        return "<Todo: id=\(id); text=\(title); completed=\(completed);>"
    }
}

extension Todo : Model {
    static var table: String {
        return "todos"
    }
    
    static var columns: [String] {
        return [
            "id",
            "title",
            "completed"
        ]
    }
    
    static var primaryKey: String {
        return "id"
    }
    
    var properties: [BaseProperty] {
        return [
            self.id,
            self.title,
            self.completed
        ]
    }
}
