//
//  UserController.swift
//  
//
//  Created by Michael Swan on 3/12/21.
//

import Fluent
import Vapor
import TTShared

struct UserController: RouteCollection {
    let userID = "userID"
    let ticketID = "ticketID"
    
    func boot(routes: RoutesBuilder) throws {
        let users = routes.grouped("users")
        users.get(use: readAll)
        users.get(":\(userID)", use: read)
        users.post(use: create)
        users.patch(":\(userID)", use: update)
        users.delete(":\(userID)", use: delete)
        users.get(":\(userID)", "tickets", use: tickets)
        users.post(":\(userID)", "addTicket", ":\(ticketID)", use: addTicket)
    }
    
    func create(req: Request) throws -> EventLoopFuture<UserDTO> {
        let userDTO = try req.content.decode(UserDTO.self)
        let user = User(user: userDTO)
        return user.save(on: req.db).map { UserDTO(user: user) }
    }
    
    func readAll(req: Request) throws -> EventLoopFuture<Page<UserDTO>> {
        return User.query(on: req.db).paginate(for: req).map { page in
            page.map { UserDTO(user: $0) }
        }
    }
    
    func read(req: Request) throws -> EventLoopFuture<UserDTO> {
        guard let id = req.parameters.get(userID, as: UUID.self) else {
            throw Abort(.badRequest)
        }
        return User.find(id, on: req.db)
            .unwrap(or: Abort(.notFound))
            .map { UserDTO(user: $0) }
    }
    
    func update(req: Request) throws -> EventLoopFuture<UserDTO> {
        guard let id = req.parameters.get(userID, as: UUID.self) else {
            throw Abort(.badRequest)
        }
        let input = try req.content.decode(UserDTO.self)
        return User.find(id, on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { user in
                user.name = input.name
                user.email = input.email
                return user.save(on: req.db)
                    .map { UserDTO(user: user) }
            }
    }
    
    #warning("Deleting a user that has tickets breaks everything!")
    func delete(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        guard let id = req.parameters.get(userID, as: UUID.self) else {
            throw Abort(.badRequest)
        }
        // TODO: Add a deleted user in a migration and assign all tickets for user to the deleted user.
        return User.find(id, on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { $0.delete(on: req.db) }
            .transform(to: .ok)
    }
    
    func tickets(req: Request) throws -> EventLoopFuture<[TicketDTO]> {
        guard let id = req.parameters.get(userID, as: UUID.self) else {
            throw Abort(.badRequest)
        }
        return User.query(on: req.db)
            .filter(\.$id == id)
            .with(\.$assignedTickets)
            .first()
            .unwrap(or: Abort(.notFound))
            .map { user in
                var ticketArray = [TicketDTO]()
                for ticket in user.assignedTickets {
                    ticketArray.append(TicketDTO(ticket: ticket, assignee: UserDTO(user: user)))
                }
                return ticketArray
            }
    }
    
    // Add Ticket
    func addTicket(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        guard let uID = req.parameters.get(userID, as: UUID.self), let tID = req.parameters.get(ticketID, as: UUID.self) else {
            throw Abort(.badRequest)
        }
        return User.find(uID, on: req.db)
            .unwrap(or: Abort(.notFound))
            .map { user in
                return Ticket.query(on: req.db)
                    .filter(\.$id == tID)
                    .set(\.$assignee.$id, to: uID)
                    .update()
            }
            .transform(to: .ok)
    }
        
}

