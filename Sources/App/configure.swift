import FluentPostgreSQL
import Vapor
import Leaf
import Authentication

/// Called before your application initializes.
///
/// [Learn More →](https://docs.vapor.codes/3.0/getting-started/structure/#configureswift)
public func configure(
    _ config: inout Config,
    _ env: inout Environment,
    _ services: inout Services
    ) throws {
    // Register providers first
    try services.register(FluentPostgreSQLProvider())
    try services.register(LeafProvider())
    //This registers the necessary services with your application to ensure authentication works.
    try services.register(AuthenticationProvider())
    
    // Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)
    
    // Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    middlewares.use(SessionsMiddleware.self) //Global middleware for your application.
    services.register(middlewares)
    
    // Configure a database
    var databases = DatabasesConfig()
    let hostname = Environment.get("DATABASE_HOSTNAME") ?? "localhost"
    let username = Environment.get("DATABASE_USER") ?? "vapor"
    
    let databaseName: String
    let databasePort: Int
    if (env == .testing) {
        databaseName = "vapor-test"
        if let testPort = Environment.get("DATABASE_PORT") {
            databasePort = Int(testPort) ?? 5433
        } else {
            databasePort = 5433
        }
    }
    else {
        databaseName = Environment.get("DATABASE_DB") ?? "vapor"
        databasePort = 5432
    }
    let password = Environment.get("DATABASE_PASSWORD") ?? "password"
    let databaseConfig = PostgreSQLDatabaseConfig(
        hostname: hostname,
        port: databasePort,
        username: username,
        database: databaseName,
        password: password)
    let database = PostgreSQLDatabase(config: databaseConfig)
    databases.add(database: database, as: .psql)
    services.register(databases)
    
    // Configure migrations
    var migrations = MigrationConfig()
    migrations.add(model: User.self, database: .psql)
    migrations.add(model: Acronym.self, database: .psql)
    migrations.add(model: Category.self, database: .psql)
    migrations.add(model: AcronymCategoryPivot.self, database: .psql)
    migrations.add(model: Token.self, database: .psql)
    //This add AdminUser to the list of migrations so the app executes the migration at the next app launch.
    //You use add(migration: database:) instead of add(model:database:) since this isn't a full model.
    //migrations.add(migration: AdminUser.self, database: .psql)
    
    
    //With the following, the AdminUser is only added to the migrations if the application is in either the development (the default) or testing environment.
    //If the environment is production, the migration won't happen.
    ///Of course, you still want to have an admin in your production environment that has a random password.  In that case you can switch on the environment inside AdminUser or you can create two versions, one for development and one for production.
    switch env {
        case .development, .testing:
            migrations.add(migration: AdminUser.self, database: .psql)
        default: break
    }
    
    
    migrations.add(migration: AddTwitterURLToUser.self, database: .psql)
    migrations.add(migration: MakeCategoriesUnique.self, database: .psql)
    services.register(migrations)
    
    // Configure the rest of your application here
    var commandConfig = CommandConfig.default()
    commandConfig.useFluentCommands()
    services.register(commandConfig)
    
    //This tells Vapor to use LeafRenderer when asked for a ViewRenderer type.
    config.prefer(LeafRenderer.self, for: ViewRenderer.self)
    
    //Tell your application to use MemoryKeyedCache when asked for the KeyedCache service.
    //The KeyedCache service is a key-value cache that backs sessions.
    //There are multiple implementations of KeyedCache - discussed in Chapter 24.
    config.prefer(MemoryKeyedCache.self, for: KeyedCache.self)
    
}
