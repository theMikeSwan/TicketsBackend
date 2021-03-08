//
//  TicketDTO+Content.swift
//  App
//
//  Created by Michael Swan on 3/3/21.
//

import Foundation
import TTShared
import Vapor

extension TicketDTO: Content {
    public convenience init(ticket: Ticket) {
        var historyArray = [TicketHistoryDTO]()
        for history in ticket.history {
            historyArray.append(TicketHistoryDTO(ticketHistory: history))
        }
        self.init(id: ticket.id, number: ticket.number, summary: ticket.summary, detail: ticket.detail, size: ticket.size, dateCreated: ticket.dateCreated, status: ticket.status, history: historyArray, type: ticket.type)
    }
}
