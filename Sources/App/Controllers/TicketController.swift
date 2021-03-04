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
        tickets.post(use: create)
        tickets.group(":\(ticketID)") { ticket in
            tickets.delete(use: delete)
//            tickets.get(use: read)
            tickets.patch(use: update)
        }
    }

    func readAll(req: Request) throws -> EventLoopFuture<Page<TicketDTO>> {
        return Ticket.query(on: req.db).paginate(for: req).map { page in
            page.map { TicketDTO(ticket: $0) }
        }
    }
    
    func create(req: Request) throws -> EventLoopFuture<TicketDTO> {
        let ticketDto = try req.content.decode(TicketDTO.self)
        let ticket = Ticket(ticket: ticketDto)
        return ticket.save(on: req.db).map { TicketDTO(ticket: ticket) }
    }
    

    func delete(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        return Ticket.find(req.parameters.get(ticketID), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { $0.delete(on: req.db) }
            .transform(to: .ok)
    }
    
    
    func read(req: Request) throws -> EventLoopFuture<TicketDTO> {
        guard let id = req.parameters.get(ticketID, as: UUID.self) else {
            throw Abort(.badRequest)
        }
        return Ticket.find(id, on: req.db)
            .unwrap(or: Abort(.notFound))
            .map { TicketDTO(ticket: $0) }
    }
    
    
    func update(req: Request) throws -> EventLoopFuture<TicketDTO> {
        guard let id = req.parameters.get(ticketID, as: UUID.self) else {
            throw Abort(.badRequest)
        }
        let input = try req.content.decode(TicketDTO.self)
        return Ticket.find(id, on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { ticket in
                ticket.summary = input.summary
                ticket.detail = input.detail
                ticket.size = input.size
                ticket.status = input.status
                return ticket.save(on: req.db)
                    .map { TicketDTO(ticket: ticket) }
            }
    }
}
