//
//  UserViews.swift
//  Swerver
//
//  Created by Julius Parishy on 12/17/15.
//  Copyright © 2015 Julius Parishy. All rights reserved.
//

import Foundation

class UserIndexView : View {
    convenience init() {
        self.init {
            t in
            BootstrapLayout.render(t, activeTab: .Home) { t in
                t.div(cssClass: "jumbotron") { t in
                    t.h1("Swerver")
                    t.h4("An MVC Framework for Web Apps & APIs in Swift")
                    
                    t.tag("hr")
                }
            }
        }
    }
}
