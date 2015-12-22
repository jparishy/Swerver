//
//  Views.swift
//  Swerver
//
//  Created by Julius Parishy on 12/17/15.
//  Copyright © 2015 Julius Parishy. All rights reserved.
//

import Foundation

class TodoIndexView : View {
    convenience init() {
        self.init {
            t in
            t.str("Hello World!")
        }
    }
}
