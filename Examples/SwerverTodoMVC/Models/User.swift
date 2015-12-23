//
//  User.swift
//  Swerver
//
//  Created by Julius Parishy on 12/22/15.
//  Copyright © 2015 Julius Parishy. All rights reserved.
//

import Foundation

class User : Model {
    required init() {
    }
    
    let id = IntProperty(column: "id")
    
    let email = StringProperty(column: "email")
    
    let encryptedPassword = StringProperty(column: "encrypted_password")
    let passwordSalt = StringProperty(column: "password_salt")
    
    class override var table: String {
        return "users"
    }
    
    class override var columns: [String] {
        return [
            "id",
            "email",
            "encrypted_password",
            "password_salt"
        ]
    }
    
    class override var primaryKey: String {
        return "id"
    }
    
    override var properties: [BaseProperty] {
        return [
            self.id,
            self.email,
            self.encryptedPassword,
            self.passwordSalt
        ]
    }
}

extension User {
    static func hashPassword(password: String, salt: String? = nil) -> String {
        if let salt = salt {
            return (password + salt).sha1()
        } else {
            return password.sha1()
        }
    }
    
    static func randomPasswordSalt() -> String {
        let bytes = (0..<16).map { _ in Character(UnicodeScalar(cs_arc4random_uniform(256))) }
        return String(bytes).sha1()
    }
    
    func authenticateWithPassword(password: String) -> Bool {
        return self.encryptedPassword.value() == User.hashPassword(password + self.passwordSalt.value())
    }
    
    func updatePassword(password: String) {
        let salt = User.randomPasswordSalt()
        self.passwordSalt.update(salt)
        
        let encrypted = User.hashPassword(password, salt: salt)
        self.encryptedPassword.update(encrypted)
    }
}

extension User : CustomStringConvertible {
    var description: String {
        return "<Todo: id=\(id); email=\(String(email));>"
    }
}