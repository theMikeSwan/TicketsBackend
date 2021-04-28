import Fluent
import FluentPostgresDriver
import Vapor

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    let databaseName: String
    let databasePort: Int
    // We will use a different db instance for testing so we need to figure out if we are testing or not.
    // Not sure this is the best way to do this as now test code is in the production app.
    if (app.environment == .testing) {
      databaseName = "vapor-test"
      if let testPort = Environment.get("DATABASE_PORT") {
        databasePort = Int(testPort) ?? 5433
      } else {
        databasePort = 5433
      }
    } else {
        databaseName = "vapor_database"
        databasePort = 5432
    }

    app.databases.use(.postgres(
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
        port: databasePort,
        username: Environment.get("DATABASE_USERNAME") ?? "vapor_username",
        password: Environment.get("DATABASE_PASSWORD") ?? "vapor_password",
        database: Environment.get("DATABASE_NAME") ?? databaseName
    ), as: .psql)

    app.migrations.add(CreateUser())
    app.migrations.add(CreateTicket())
    app.migrations.add(CreateTicketHistory())
    app.logger.logLevel = .debug
    try app.autoMigrate().wait()

    // register routes
    try routes(app)
}
