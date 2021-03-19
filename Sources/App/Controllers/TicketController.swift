//
//  TicketController.swift
//  App
//
//  Created by Michael Swan on 3/2/21.
//

import Fluent
import Vapor
import TTShared

struct TicketController: RouteCollection {
    let ticketID = "ticketID"
    
    func boot(routes: RoutesBuilder) throws {
        let tickets = routes.grouped("tickets")
        tickets.get(use: readAll)
        tickets.get(":\(ticketID)", use: read)
        tickets.post(use: create)
        tickets.patch(":\(ticketID)", use: update)
        tickets.delete(":\(ticketID)", use: delete)
        tickets.get(":\(ticketID)", "history", use: ticketHistory)
        // This doesn't seem to work for some reason.
//        tickets.group(":\(ticketID)") { ticket in
//            tickets.delete(use: delete)
//            tickets.get(use: read)
//            tickets.patch(use: update)
//        }
    }

    func readAll(req: Request) throws -> EventLoopFuture<Page<TicketDTO>> {
        return Ticket.query(on: req.db)
            .with(\.$assignee)
            .paginate(for: req)
            .map { page in
                page.map { TicketDTO(ticket: $0, assignee: UserDTO(user: $0.assignee)) }
            }
    }
    
    func create(req: Request) throws -> EventLoopFuture<TicketDTO> {
        let ticketDto = try req.content.decode(TicketDTO.self)
        let assigneeDTO = ticketDto.assignee
        // We force unwrap the assignee ID when creating a Ticket from TicketDTO, verify it has a value here to save the crash later.
        // Also a ticket has to have someone assigned to it even from the start.
        guard assigneeDTO.id != nil else {
            throw Abort(.badRequest)
        }
        // TODO: Make sure the user actually exists before createing the ticket
        let ticket = Ticket(ticket: ticketDto)
        return ticket.save(on: req.db).map { TicketDTO(ticket: ticket, assignee: assigneeDTO) }
    }
    

    func delete(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        guard let id = req.parameters.get(ticketID, as: UUID.self) else {
            throw Abort(.badRequest)
        }
        return Ticket.find(id, on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { $0.delete(on: req.db) }
            .transform(to: .ok)
    }
    
    
    func read(req: Request) throws -> EventLoopFuture<TicketDTO> {
        guard let id = req.parameters.get(ticketID, as: UUID.self) else {
            throw Abort(.badRequest)
        }
        return Ticket.query(on: req.db)
            .filter(\.$id == id)
            .with(\.$assignee)
            .first()
            .unwrap(or: Abort(.notFound))
            .map { TicketDTO(ticket: $0, assignee: UserDTO(user: $0.assignee)) }
    }
    
    
    func update(req: Request) throws -> EventLoopFuture<TicketDTO> {
        guard let id = req.parameters.get(ticketID, as: UUID.self) else {
            throw Abort(.badRequest)
        }
        let input = try req.content.decode(TicketDTO.self)
        return Ticket.query(on: req.db)
            .filter(\.$id == id)
            .with(\.$assignee)
            .first()
            .unwrap(or: Abort(.notFound))
            .flatMap { ticket in
                // Things like ticket number and date created can't be changed so we ignore them here.
                ticket.summary = input.summary
                ticket.detail = input.detail
                ticket.size = input.size
                if ticket.status != input.status {
                    ticket.status = input.status
                    let history = TicketHistory(id: nil, status: ticket.status, ticketId: id)
                    // The docs don't have the `_ =` at the start, but the compiler issues an unused result warning.
                    _ = ticket.$history.create(history, on: req.db)
                }
                return ticket.save(on: req.db)
                    .map { TicketDTO(ticket: ticket, assignee: UserDTO(user: ticket.assignee)) }
            }
    }
    
    func ticketHistory(req: Request) throws -> EventLoopFuture<[TicketHistoryDTO]> {
        guard let id = req.parameters.get(ticketID, as: UUID.self) else {
            throw Abort(.badRequest)
        }
        return Ticket.query(on: req.db)
            .filter(\.$id == id)
            .with(\.$history)
            .first()
            .unwrap(or: Abort(.notFound))
            .map { ticket in
                var historyArray = [TicketHistoryDTO]()
                for item in ticket.history {
                    historyArray.append(TicketHistoryDTO(ticketHistory: item))
                }
                return historyArray
            }
    }
}
