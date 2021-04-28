//
//  Ticket.swift
//  App
//
//  Created by Michael Swan on 3/2/21.
//

import Foundation
import Vapor
import TTShared
import Fluent

public final class Ticket: Model {
    struct FieldKeys {
        static var number: FieldKey { "number" }
        static var summary: FieldKey { "summary" }
        static var detail: FieldKey { "detail" }
        static var size: FieldKey { "size" }
        static var dateCreated: FieldKey { "dateCreated" }
        static var status: FieldKey { "status" }
        static var type: FieldKey { "type" }
    }
    
    @ID(key: .id)
    public var id: UUID?
    @Field(key: FieldKeys.number)
    public var number: String
    @Field(key: FieldKeys.summary)
    public var summary: String
    @Field(key: FieldKeys.detail)
    public var detail: String
    @Field(key: FieldKeys.size)
    public var size: String
    @Field(key: FieldKeys.dateCreated)
    public var dateCreated: Date
    @Field(key: FieldKeys.status)
    public var status: TicketStatus
    @Children(for: \.$ticket)
    public var history: [TicketHistory]
    @Field(key: FieldKeys.type)
    public var type: TicketType
    
    public static var schema = "tickets"
    
    public init(id: UUID?, number: String, summary: String, detail: String, size: String, dateCreated: Date = Date(), status: TicketStatus, type: TicketType) {
        self.id = id
        self.number = number
        self.summary = summary
        self.detail = detail
        self.size = size
        self.dateCreated = dateCreated
        self.status = status
        self.type = type
    }
    
    public convenience init(ticket: TicketDTO) {
        self.init(id: ticket.id, number: ticket.number, summary: ticket.summary, detail: ticket.detail, size: ticket.size, dateCreated: ticket.dateCreated, status: ticket.status, type: ticket.type)
    }
    
    public init() {  }
}
