//
//  File.swift
//  
//
//  Created by Mike Swan on 3/8/21.
//

import Fluent

struct CreateTicketHistory: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(TicketHistory.schema)
            .id()
            .field(TicketHistory.FieldKeys.date, .date, .required)
            .field(TicketHistory.FieldKeys.status, .string, .required)
            .field(TicketHistory.FieldKeys.ticket, .uuid)
            .foreignKey(TicketHistory.FieldKeys.ticket, references: Ticket.schema, .id, onDelete: .cascade, onUpdate: .noAction)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(TicketHistory.schema).delete()
    }
}
