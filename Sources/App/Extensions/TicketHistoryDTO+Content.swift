//
//  File.swift
//  
//
//  Created by Mike Swan on 3/7/21.
//

import Foundation
import TTShared
import Vapor

extension TicketHistoryDTO: Content {
    public convenience init(ticketHistory: TicketHistory) {
        self.init(id: ticketHistory.id, date: ticketHistory.date, status: ticketHistory.status)
    }
}
