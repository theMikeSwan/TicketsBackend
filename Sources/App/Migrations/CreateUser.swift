//
//  CreateUser.swift
//  
//
//  Created by Michael Swan on 3/12/21.
//

import Fluent

struct CreateUser: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(User.schema)
            .id()
            .field(User.FieldKeys.name, .string, .required)
            .field(User.FieldKeys.email, .string, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(Ticket.schema).delete()
    }
}
