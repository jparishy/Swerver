//
//  Note.swift
//  Swerver
//
//  Created by Julius Parishy on 12/11/15.
//  Copyright © 2015 Julius Parishy. All rights reserved.
//

import Foundation

class Todo : Model {
    required init() {
    }
    
    let id = IntProperty(column: "id")
    
    let title = StringProperty(column: "title")
    let completed = BoolProperty(column: "completed")
    
    class override var table: String {
        return "todos"
    }
    
    class override var columns: [String] {
        return [
            "id",
            "title",
            "completed"
        ]
    }
    
    class override var primaryKey: String {
        return "id"
    }
    
    override var properties: [BaseProperty] {
        return [
            self.id,
            self.title,
            self.completed
        ]
    }
}

extension Todo : CustomStringConvertible {
    var description: String {
        return "<Todo: id=\(id); text=\(title); completed=\(completed);>"
    }
}
