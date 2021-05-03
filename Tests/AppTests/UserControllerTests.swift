@testable import App
import XCTVapor
import Fluent
import TTShared

final class UserControllerTests: XCTestCase {
    private var app: Application!
    private let users = "users"
    private let userName = "Hermione Grainger"
    private let email = "HermioneG@hogwarts.edu"
    private let badUser = "{\"name\":\"Ron Weasley\"}"
    private let fakeID = UUID().uuidString
    private let badID = "NotEvenCloseToAUUID"
    
    override func setUp() {
        app = try! Application.testable()
    }
    
    override func tearDown() {
        app.shutdown()
    }

    func testCreateUserWithGoodData() throws {
        let user = UserDTO(id: nil, name: userName, email: email)
        try app.test(.POST, users, beforeRequest: { (req) in
            try req.content.encode(user)
        }, afterResponse: { (res) in
            XCTAssertEqual(res.status, .ok)
            let returnedUser = try res.content.decode(UserDTO.self)
            XCTAssertNotNil(returnedUser.id)
            XCTAssertEqual(returnedUser.name, userName)
            XCTAssertEqual(returnedUser.email, email)
        })
    }

    func testCreateUserWithBadData() throws {
        try app.test(.POST, users, beforeRequest: { (req) in
            try req.content.encode(badUser)
        }, afterResponse: { (res) in
            XCTAssertEqual(res.status, .unsupportedMediaType)
        })
    }

    func testReadAllUsers() throws {
        let user = try User.create(name: userName, email: email, on: app.db)
        _ = try User.create(on: app.db)
        try app.test(.GET, users) { res in
            XCTAssertEqual(res.status, .ok)
            let contents = try res.content.decode(Page<UserDTO>.self)
            let users = contents.items
            XCTAssertEqual(users.count, 2)
            let returnedUser = users[0]
            XCTAssertEqual(returnedUser.name, userName)
            XCTAssertEqual(returnedUser.id, user.id)
            XCTAssertEqual(returnedUser.email, email)
        }
    }

    func testReadRealUser() throws {
        let user = try User.create(name: userName, email: email, on: app.db)
        try app.test(.GET, "\(users)/\(user.id!)") { res in
            XCTAssertEqual(res.status, .ok)
            let returnedUser = try res.content.decode(UserDTO.self)
            XCTAssertEqual(returnedUser.name, userName)
            XCTAssertEqual(returnedUser.id, user.id)
            XCTAssertEqual(returnedUser.email, email)
        }
    }

    func testReadFakeUser() throws {
        try app.test(.GET, "\(users)/\(fakeID)") { res in
            XCTAssertEqual(res.status, .notFound)
        }
    }

    func testReadUserWithBadURL() throws {
        try app.test(.GET, "\(users)/\(badID)") { res in
            XCTAssertEqual(res.status, .badRequest)
        }
    }

    func testUpdateRealUser() throws {
        let user = try User.create(on: app.db)
        let userDTO = UserDTO(id: user.id!, name: userName, email: email)
        try app.test(.PATCH, "\(users)/\(user.id!)", beforeRequest: { (req) in
            try req.content.encode(userDTO)
        }, afterResponse: { (res) in
            XCTAssertEqual(res.status, .ok)
            let returnedUser = try res.content.decode(UserDTO.self)
            XCTAssertEqual(returnedUser.name, userName)
            XCTAssertEqual(returnedUser.email, email)
        })
    }

    func testUpdateFakeUser() throws {
        let userDTO = UserDTO(id: nil, name: userName, email: email)
        try app.test(.PATCH, "\(users)/\(fakeID)", beforeRequest: { (req) in
            try req.content.encode(userDTO)
        }, afterResponse: { (res) in
            XCTAssertEqual(res.status, .notFound)
        })
    }

    func testUpdateUserWithMissingData() throws {
        let user = try User.create(on: app.db)
        try app.test(.PATCH, "\(users)/\(user.id!)", beforeRequest: { (req) in
            try req.content.encode(badUser)
        }, afterResponse: { (res) in
            XCTAssertEqual(res.status, .unsupportedMediaType)
        })
    }

    func testDeleteRealUser() throws {
        let user = try User.create(on: app.db)
        try app.test(.DELETE, "\(users)/\(user.id!)") { res in
            XCTAssertEqual(res.status, .ok)
        }
    }
    
    // Will eventually need a test to verify correct behavior when a user with tickets is deleted.

    func testDeleteFakeUser() throws {
        try app.test(.DELETE, "\(users)/\(fakeID)") { res in
            XCTAssertEqual(res.status, .notFound)
        }
    }

    func testDeleteUserWithBadURL() throws {
        try app.test(.DELETE, "\(users)/\(badID)") { res in
            XCTAssertEqual(res.status, .badRequest)
        }
    }

    func testGetTicketsForRealUser() throws {
        let user = try User.create(on: app.db)
        let ticket = try Ticket.create(assignee: user.id!, on: app.db)
        _ = try Ticket.create(assignee: user.id!, on: app.db)
        try app.test(.GET, "\(users)/\(user.id!)/tickets") { res in
            XCTAssertEqual(res.status, .ok)
            let tickets = try res.content.decode([TicketDTO].self)
            XCTAssertEqual(tickets.count, 2)
            XCTAssertEqual(tickets[0].id, ticket.id)
        }
    }

    func testGetTicketsForFakeUser() throws {
        try app.test(.GET, "\(users)/\(fakeID)/tickets") { res in
            XCTAssertEqual(res.status, .notFound)
        }
    }

    func testGetTicketsForUserWithBadURL() throws {
        try app.test(.GET, "\(users)/\(badID)/tickets") { res in
            XCTAssertEqual(res.status, .badRequest)
        }
    }

    func testAssignTicketToRealUser() throws {
        let originalUser = try User.create(on: app.db)
        let newUser = try User.create(name: userName, email: email, on: app.db)
        let ticket = try Ticket.create(assignee: originalUser.id!, on: app.db)
        try app.test(.POST, "\(users)/\(newUser.id!)/addTicket/\(ticket.id!)") { res in
            XCTAssertEqual(res.status, .ok)
        }
        // TODO: Get tickets for newUser and verify the ticket is there.
    }

    func testAssignTicketToFakeUser() throws {
        let user = try User.create(on: app.db)
        let ticket = try Ticket.create(assignee: user.id!, on: app.db)
        try app.test(.POST, "\(users)/\(badID)/addTicket/\(ticket.id!)") { res in
            XCTAssertEqual(res.status, .badRequest)
        }
    }
    
    func testAssignFakeTicketToRealUser() throws {
        let user = try User.create(on: app.db)
        try app.test(.POST, "\(users)/\(user.id!)/addTicket/\(fakeID)") { res in
            XCTAssertEqual(res.status, .notFound)
        }
    }
}

