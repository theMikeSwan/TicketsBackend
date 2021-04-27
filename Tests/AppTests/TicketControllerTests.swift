@testable import App
import XCTVapor
import Fluent
import TTShared

final class TicketControllerTests: XCTestCase {
    private var app: Application!
    private let tickets = "tickets"
    private let badTicket = "{\"number\":\"TST-0003\"}"
    private let fakeID = UUID().uuidString
    private let badID = "NotEvenCloseToAUUID"
    private let number = "TST-1001"
    private let summary = "This is only a test"
    private let detail = "Nothing to see here, move along."
    private let size = "3"
    // Fluent always returns midnight for the time with it dates.
    // We want to verify that sending a new date created for a ticket fails.
    // To teest this we set our default date to yesterday or the day before.
    // We don't really care which as long as it isn't today.
    // (We use today for the updated date when testing ticket update.)
    // As a result we can use 60 seconds * 60 minutes * 26 hours = 93_600
    // We use 26 hours to ensure we are always at least a day earlier
    // Even at 11:59pm on spring forward day.
    private let dateCreated = Date().addingTimeInterval(-93_600)
    private let status = TicketStatus.todo
    private let type = TicketType.story
    private let dateFormatter = DateFormatter()
    
    override func setUp() {
        app = try! Application.testable()
        dateFormatter.timeStyle = .none
        dateFormatter.dateStyle = .medium
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
    }
    
    override func tearDown() {
        app.shutdown()
    }

    func testCreateTicketWithGoodData() throws {
        let user = try User.create(on: app.db)
        let userDTO = UserDTO(user: user)
        let ticketDTO = TicketDTO(id: nil, number: number, summary: summary, detail: detail, size: size, dateCreated: dateCreated, status: status, type: type, assignee: userDTO)
        try app.test(.POST, tickets, beforeRequest: { (req) in
            try req.content.encode(ticketDTO)
        }, afterResponse: { (res) in
            XCTAssertEqual(res.status, .ok)
            let testTicket = try res.content.decode(TicketDTO.self)
            XCTAssertEqual(testTicket.number, number)
            XCTAssertNotNil(testTicket.id)
            XCTAssertEqual(testTicket.summary, summary)
            XCTAssertEqual(testTicket.detail, detail)
            XCTAssertEqual(testTicket.size, size)
            let returnedDateString = dateFormatter.string(from: testTicket.dateCreated)
            let referenceDateString = dateFormatter.string(from: dateCreated)
            XCTAssertEqual(returnedDateString, referenceDateString)
            XCTAssertEqual(testTicket.status, status)
            XCTAssertEqual(testTicket.type, type)
            XCTAssertEqual(testTicket.assignee.id, user.id!)
        })
    }

    func testCreateTicketWithBadData() throws {
        try app.test(.POST, tickets, beforeRequest: { (req) in
            try req.content.encode(badTicket)
        }, afterResponse: { (res) in
            XCTAssertNotEqual(res.status, .ok)
        })
    }
    
    func testCreateTicketWithMissingAssigneeIDFails() throws {
        let userDTO = UserDTO(id: nil, name: "", email: "")
        let ticketDTO = TicketDTO(id: nil, number: number, summary: summary, detail: detail, size: size, dateCreated: dateCreated, status: status, type: type, assignee: userDTO)
        try app.test(.POST, tickets, beforeRequest: { (req) in
            try req.content.encode(ticketDTO)
        }, afterResponse: { (res) in
            XCTAssertEqual(res.status, .badRequest)
        })
    }

    func testReadAllTickets() throws {
        let user = try User.create(on: app.db)
        let ticket = try Ticket.create(number: number, summary: summary, detail: detail, size: size, dateCreated: dateCreated, status: status, type: type, assignee: user.id!, on: app.db)
        _ = try Ticket.create(assignee: user.id!, on: app.db)
        try app.test(.GET, tickets) { res in
            XCTAssertEqual(res.status, .ok)
            let contents = try res.content.decode(Page<TicketDTO>.self)
            let tickets = contents.items
            XCTAssertEqual(tickets.count, 2)
            let testTicket = tickets[0]
            XCTAssertEqual(testTicket.number, number)
            XCTAssertEqual(testTicket.id, ticket.id)
            XCTAssertEqual(testTicket.summary, summary)
            XCTAssertEqual(testTicket.detail, detail)
            XCTAssertEqual(testTicket.size, size)
            let returnedDateString = dateFormatter.string(from: testTicket.dateCreated)
            let referenceDateString = dateFormatter.string(from: dateCreated)
            XCTAssertEqual(returnedDateString, referenceDateString)
            XCTAssertEqual(testTicket.status, status)
            XCTAssertEqual(testTicket.type, type)
            XCTAssertEqual(testTicket.assignee.id, user.id!)
        }
    }

    func testReadOneTicket() throws {
        let user = try User.create(on: app.db)
        let ticket = try Ticket.create(number: number, summary: summary, detail: detail, size: size, dateCreated: dateCreated, status: status, type: type, assignee: user.id!, on: app.db)

        let id = ticket.id!
        try app.test(.GET, "\(tickets)/\(id)") { res in
            XCTAssertEqual(res.status, .ok)
            let testTicket = try res.content.decode(TicketDTO.self)
            XCTAssertEqual(testTicket.number, number)
            XCTAssertEqual(testTicket.id, ticket.id)
            XCTAssertEqual(testTicket.summary, summary)
            XCTAssertEqual(testTicket.detail, detail)
            XCTAssertEqual(testTicket.size, size)
            let returnedDateString = dateFormatter.string(from: testTicket.dateCreated)
            let referenceDateString = dateFormatter.string(from: dateCreated)
            XCTAssertEqual(returnedDateString, referenceDateString)
            XCTAssertEqual(testTicket.status, status)
            XCTAssertEqual(testTicket.type, type)
            XCTAssertEqual(testTicket.assignee.id, user.id!)
        }
    }

    func testReadOneFakeTicket() throws {
        try app.test(.GET, "\(tickets)/\(fakeID)") { res in
            XCTAssertEqual(res.status, .notFound)
        }
    }

    func testReadTicketWithBadRequest() throws {
        try app.test(.GET, "\(tickets)/\(badID)") { res in
            XCTAssertEqual(res.status, .badRequest)
        }
    }

    func testUpdateRealTicket() throws {
        let user = try User.create(on: app.db)
        let ticket = try Ticket.create(number: number, summary: summary, detail: detail, size: size, dateCreated: dateCreated, status: status, type: type, assignee: user.id!, on: app.db)
        let id = ticket.id!
        let newNumber = "TST-1002"
        let newSummary = "Modified summary"
        let newDetail = "Modified details"
        let newSize = "5"
        let newDate = Date()
        let newStatus = TicketStatus.inProgress
        let newType = TicketType.bug
        let newUser = try User.create(name: "Albus Dumbledore", email: "", on: app.db)
        let newUserDTO = UserDTO(user: newUser)
        let ticketDTO = TicketDTO(id: id, number: newNumber, summary: newSummary, detail: newDetail, size: newSize, dateCreated: newDate, status: newStatus, type: newType, assignee: newUserDTO)
        
        try app.test(.PATCH, "\(tickets)/\(id)", beforeRequest: { (req) in
            try req.content.encode(ticketDTO)
        }, afterResponse: { (res) in
            XCTAssertEqual(res.status, .ok)
            let testTicket = try res.content.decode(TicketDTO.self)
            XCTAssertEqual(testTicket.number, number)
            XCTAssertEqual(testTicket.id, ticket.id)
            XCTAssertEqual(testTicket.summary, newSummary)
            XCTAssertEqual(testTicket.detail, newDetail)
            XCTAssertEqual(testTicket.size, newSize)
            let returnedDateString = dateFormatter.string(from: testTicket.dateCreated)
            let referenceDateString = dateFormatter.string(from: dateCreated)
            XCTAssertEqual(returnedDateString, referenceDateString)
            XCTAssertEqual(testTicket.status, newStatus)
            XCTAssertEqual(testTicket.type, type)
            XCTAssertEqual(testTicket.assignee.id, user.id!)
        })
    }

    func testUpdateFakeTicket() throws {
        let user = try User.create(on: app.db)
        let ticket = try Ticket.create(number: number, summary: summary, detail: detail, size: size, dateCreated: dateCreated, status: status, type: type, assignee: user.id!, on: app.db)
        let id = ticket.id!
        let newNumber = "TST-1002"
        let newSummary = "Modified summary"
        let newDetail = "Modified details"
        let newSize = "5"
        let newDate = Date()
        let newStatus = TicketStatus.inProgress
        let newType = TicketType.bug
        let newUser = try User.create(name: "Albus Dumbledore", email: "", on: app.db)
        let newUserDTO = UserDTO(user: newUser)
        let ticketDTO = TicketDTO(id: id, number: newNumber, summary: newSummary, detail: newDetail, size: newSize, dateCreated: newDate, status: newStatus, type: newType, assignee: newUserDTO)
        
        try app.test(.PATCH, "\(tickets)/\(fakeID)", beforeRequest: { (req) in
            try req.content.encode(ticketDTO)
        }, afterResponse: { (res) in
            XCTAssertEqual(res.status, .notFound)
        })
    }

    func testUpdateRealTicketWithBadData() throws {
        let user = try User.create(on: app.db)
        let ticket = try Ticket.create(number: number, summary: summary, detail: detail, size: size, dateCreated: dateCreated, status: status, type: type, assignee: user.id!, on: app.db)
        let id = ticket.id!
        try app.test(.PATCH, "\(tickets)/\(id)", beforeRequest: { (req) in
            try req.content.encode(badTicket)
        }, afterResponse: { (res) in
            print(res.status)
            XCTAssertNotEqual(res.status, .ok)
        })
    }

    func testUpdateTicketWithBadURL() throws {
        let user = try User.create(on: app.db)
        let ticket = try Ticket.create(number: number, summary: summary, detail: detail, size: size, dateCreated: dateCreated, status: status, type: type, assignee: user.id!, on: app.db)
        let id = ticket.id!
        let newSummary = "Modified summary"
        let newDetail = "Modified details"
        let newSize = "5"
        let newStatus = TicketStatus.inProgress
        let userDTO = UserDTO(user: user)
        let ticketDTO = TicketDTO(id: id, number: number, summary: newSummary, detail: newDetail, size: newSize, dateCreated: dateCreated, status: newStatus, type: type, assignee: userDTO)
        
        try app.test(.PATCH, "\(tickets)/\(badID)", beforeRequest: { (req) in
            try req.content.encode(ticketDTO)
        }, afterResponse: { (res) in
            XCTAssertEqual(res.status, .badRequest)
        })
    }

    func testDeleteRealTicket() throws {
        let user = try User.create(on: app.db)
        let ticket = try Ticket.create(assignee: user.id!, on: app.db)
        try app.test(.DELETE, "\(tickets)/\(ticket.id!)") { res in
            XCTAssertEqual(res.status, .ok)
        }
    }

    func testDeleteFakeTicket() throws {
        try app.test(.DELETE, "\(tickets)/\(fakeID)") { res in
            XCTAssertEqual(res.status, .notFound)
        }
    }

    func testDeleteTicketWithBadURL() throws {
        try app.test(.DELETE, "\(tickets)/\(badID)") { res in
            XCTAssertEqual(res.status, .badRequest)
        }
    }

    func testGetHistoryForRealTicket() throws {
        let user = try User.create(on: app.db)
        let ticket = try Ticket.create(assignee: user.id!, on: app.db)
        try app.test(.GET, "\(tickets)/\(ticket.id!)/history") { res in
            XCTAssertEqual(res.status, .ok)
            let history = try res.content.decode([TicketHistoryDTO].self)
            XCTAssertNotNil(history)
            XCTAssertEqual(history.count, 0)
        }
    }

    func testGetHistoryForFakeTicket() throws {
        try app.test(.GET, "/tickets/\(fakeID)/history") {res in
            XCTAssertEqual(res.status, .notFound)
        }
    }

    func testGetHistoryWithBadURL() throws {
        try app.test(.GET, "/tickets/\(badID)/history") {res in
            XCTAssertEqual(res.status, .badRequest)
        }
    }

    func testChangeTicketStatusAddsHistory() throws {
        let user = try User.create(on: app.db)
        let ticket = try Ticket.create(assignee: user.id!, on: app.db)
        let userDTO = UserDTO(user: user)
        let ticketDTO = TicketDTO(ticket: ticket, assignee: userDTO)
        ticketDTO.status = .inProgress
        
        let now = Date()
        let id = ticket.id!
        try app.test(.PATCH, "\(tickets)/\(id)", beforeRequest: { (req) in
            try req.content.encode(ticketDTO)
        }, afterResponse: { (res) in
            XCTAssertEqual(res.status, .ok)
        })
        try app.test(.GET, "\(tickets)/\(id)/history") { res in
            XCTAssertEqual(res.status, .ok)
            let history = try res.content.decode([TicketHistoryDTO].self)
            XCTAssertEqual(history.count, 1)
            let returnedDateString = dateFormatter.string(from: history[0].date)
            let referenceDateString = dateFormatter.string(from: now)
            XCTAssertEqual(returnedDateString, referenceDateString)
        }
    }
}
