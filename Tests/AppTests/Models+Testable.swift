//
//  File.swift
//  
//
//  Created by Michael Swan on 4/16/21.
//

@testable import App
import Fluent
import TTShared
import Foundation

// Putting these all in one file since each extension is one method and they all do the same thing (create test instances of the model objects and save them).

extension Ticket {
    static func create(number: String = "TST-0001", summary: String = "My homework sucks", detail: String = "Please write it for me!", size: String = "1", dateCreated: Date = Date(), status: TicketStatus = .todo, type: TicketType = .story, assignee: UUID, on database: Database
      ) throws -> Ticket {
        let ticket = Ticket(id: nil, number: number, summary: summary, detail: detail, size: size, dateCreated: dateCreated, status: status, type: type, assignee: assignee)
        try ticket.save(on: database).wait()
        return ticket
      }
}

extension User {
    static func create(name: String = "Harry Potter", email: String = "harry.potter@hogwarts.edu", on database: Database) throws -> User {
        let user = User(id: nil, name: name, email: email)
        try user.save(on: database).wait()
        return user
      }
}
