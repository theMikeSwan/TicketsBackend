//
//  File.swift
//  
//
//  Created by Mike Swan on 3/7/21.
//

import Foundation
import Vapor
import TTShared
import Fluent

public final class TicketHistory: Model {
    
    struct FieldKeys {
        static var date: FieldKey { "date" }
        static var status: FieldKey { "status" }
        static var ticket: FieldKey { "ticket" }
    }
    
    @ID(key: .id)
    public var id: UUID?
    @Field(key: FieldKeys.date)
    public var date: Date
    @Field(key: FieldKeys.status)
    public var status: TicketStatus
    @Parent(key: FieldKeys.ticket)
    var ticket: Ticket
    
    public static var schema = "ticketHistory"
    
    init(id: UUID?, date: Date = Date(), status: TicketStatus, ticketId: UUID) {
        self.id = id
        self.date = date
        self.status = status
        self.$ticket.id = ticketId
    }
    
//    convenience init(ticketHistory: TicketHistoryDTO) {
//        self.init(id: ticketHistory.id, date: ticketHistory.date, status: ticketHistory.status)
//    }
    
    public init() {  }
}
