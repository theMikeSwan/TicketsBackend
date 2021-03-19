//
//  User.swift
//  
//
//  Created by Michael Swan on 3/12/21.
//

import Foundation
import Vapor
import TTShared
import Fluent

public final class User: Model {
    
    struct FieldKeys {
        static var name: FieldKey { "name" }
        static var email: FieldKey { "email" }
    }
    
    @ID(key: .id)
    public var id: UUID?
    @Field(key: FieldKeys.name)
    public var name: String
    @Field(key: FieldKeys.email)
    public var email: String
    @Children(for: \.$assignee)
    public var assignedTickets: [Ticket]
    
    public static var schema = "users"

    public init(id: UUID?, name: String, email: String) {
        self.id = id
        self.name = name
        self.email = email
    }
    
    public convenience init(user: UserDTO) {
        self.init(id: user.id, name: user.name, email: user.email)
    }
    
    public init() { }
}
