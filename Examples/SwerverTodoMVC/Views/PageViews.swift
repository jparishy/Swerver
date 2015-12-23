//
//  PageViews.swift
//  Swerver
//
//  Created by Julius Parishy on 12/22/15.
//  Copyright © 2015 Julius Parishy. All rights reserved.
//

import Foundation

class PageHomeView : View {
    convenience init(user: User?) {
        self.init {
            t in
            BootstrapLayout.render(t, activeTab: .Home) { t in
                t.div(cssClass: "jumbotron") { t in
                    t.h1("Swerver")
                    t.h4("An MVC Framework for Web Apps & APIs in Swift")
                    
                    t.tag("hr")
                    
                    if let user = user {
                        t.p("You are logged in as: \(user.email.value())")
                    }
                }
            }
        }
    }
}

class PageAboutView : View {
    convenience init() {
        self.init {
            t in
            BootstrapLayout.render(t, activeTab: .About) { t in
                t.div(cssClass: "jumbotron") { t in
                    t.h2("About Swerver")
                    t.tag("hr")
                }
            }
        }
    }
}

class PageContributingView : View {
    convenience init() {
        self.init {
            t in
            BootstrapLayout.render(t, activeTab: .Contributing) { t in
                t.div(cssClass: "jumbotron") { t in
                    t.h2("Contributing")
                    t.tag("hr")
                }
            }
        }
    }
}

