//
//  UserDTO+Content.swift
//  
//
//  Created by Michael Swan on 3/12/21.
//

import Foundation
import TTShared
import Vapor

extension UserDTO: Content {
    public convenience init(user: User) {
        self.init(id: user.id, name: user.name, email: user.email)
    }
}
