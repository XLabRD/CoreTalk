import FluentSQLite
import Vapor

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    // Register providers first
    try services.register(FluentSQLiteProvider())

    // Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)

    // Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    // middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    services.register(middlewares)

    // Configure a SQLite database
    let sqlite = try SQLiteDatabase(storage: .memory)

    // Register the configured SQLite database to the database config.
    var databases = DatabasesConfig()
    databases.add(database: sqlite, as: .sqlite)
    services.register(databases)

    // Configure migrations
    var migrations = MigrationConfig()
    migrations.add(model: Client.self, database: .sqlite)
    services.register(migrations)
    
    /// ########################[ CORETALK/MODELS ]###############################
    let websockets = NIOWebSocketServer.default()
    
    //CORETALK
    
    let ping = Ping()
    let auth = Authentication()
    let admin = Admin()
    
    let crServices:[CoreTalkService] = [ping, auth, admin]
    
    //CORETALK
    let socketManager = CoreTalkServer(with: crServices)
    
    socketManager.sockets(websockets)
    services.register(websockets, as: WebSocketServer.self)
}
