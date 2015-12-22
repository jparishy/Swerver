//
//  SessionViews.swift
//  Swerver
//
//  Created by Julius Parishy on 12/17/15.
//  Copyright © 2015 Julius Parishy. All rights reserved.
//

import Foundation

class SessionIndexView : View {
    convenience init(username: String?) {
        self.init {
            t in
            t.html { t in
                t.body { t in
                    if let username = username {
                        t.h1("Signed in as \(username)!")
                        t.a("/sessions/sign_out", contents: "Sign Out")
                    } else {
                        t.h1("Sign In", attrs: ["style":"font-size: 2.5em"])
                        t.form("/sessions") { t in
                            t.label("Username:")
                            t.text_field("username")
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

