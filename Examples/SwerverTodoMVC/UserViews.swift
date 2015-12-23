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

class UserNewView : View {
    convenience init() {
        self.init {
            t in
            BootstrapLayout.render(t, activeTab: .Home) { t in
                t.div(cssClass: "jumbotron") { t in
                    t.h1("Create an Account")
                    t.h4("Enter your email and choose a password")
                    
                    t.tag("hr")
                    
                    t.div(cssClass: "container", attrs: ["style":"max-width:400px;margin-left:auto;margin-right:auto;"]) { t in
                        t.form("/users/", cssClass: "form-signin") { t in
                            t.div(cssClass: "row") { t in
                                t.label("Email Address", attrs: ["for":"email"])
                            }
                            t.div(cssClass: "row") { t in
                                t.input("email", name: "email", attrs: ["placeholder":"Email Address"])
                            }
                            
                            t.div(cssClass: "row") { t in
                                t.label("Password", attrs: ["for":"password"])
                            }
                            t.div(cssClass: "row") { t in
                                t.input("password", name: "password", attrs: ["placeholder":"Password"])
                            }
                            
                            t.div(cssClass: "row") { t in
                                t.tag("br")
                                t.submit("Submit", cssClass: "btn btn-primary")
                            }
                        }
                    }
                }
            }
        }
    }
}

class UserShowView : View {
    convenience init(userID: Int) {
        self.init {
            t in
            BootstrapLayout.render(t, activeTab: .Home) { t in
                t.div(cssClass: "jumbotron") { t in
                    t.h2("User: \(userID)")
                }
            }
        }
    }
}
