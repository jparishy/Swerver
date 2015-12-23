//
//  SessionViews.swift
//  Swerver
//
//  Created by Julius Parishy on 12/17/15.
//  Copyright © 2015 Julius Parishy. All rights reserved.
//

import Foundation

class SessionIndexView : View {
    convenience init(user: User?) {
        self.init {
            t in
            t.html { t in
                t.body { t in
                    if let user = user {
                        t.h1("Signed in as \(user.email.value())!")
                        t.a("/sign_out", contents: "Sign Out")
                    } else {
                        t.h1("Sign In", attrs: ["style":"font-size: 2.5em"])
                        
                        if t.flash.count > 0 {
                            for (k,v) in t.flash {
                                t.div(cssClass: "flash flash-\(k)") { t in
                                    t.p(v)
                                }
                            }
                        }
                        
                        t.form("/sessions") { t in
                            t.label("Email:")
                            t.text_field("email")
                            t.label("Password:")
                            t.secure_text_field("password")
                            t.submit("Sign In")
                        }
                    }
                }
            }
        }
    }
}

