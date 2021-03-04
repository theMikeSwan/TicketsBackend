//
//  CreateTicket.swift
//  App
//
//  Created by Michael Swan on 3/2/21.
//

import Fluent

struct CreateTicket: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(Ticket.schema)
            .id()
            .field(Ticket.FieldKeys.number, .string, .required)
            .field(Ticket.FieldKeys.summary, .string, .required)
            .field(Ticket.FieldKeys.detail, .string, .required)
            .field(Ticket.FieldKeys.size, .string, .required)
            .field(Ticket.FieldKeys.status, .string)
            .field(Ticket.FieldKeys.dateCreated, .date, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(Ticket.schema).delete()
    }
}

