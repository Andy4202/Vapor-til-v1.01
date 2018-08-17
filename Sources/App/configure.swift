import FluentPostgreSQL
import Vapor

/// Called before your application initializes.
public func configure(
    _ config: inout Config,
    _ env: inout Environment,
    _ services: inout Services)
    throws {
    
    /// Register providers first
    // Register the FluentPostgreSQLiteProvider as a service to allow the application to interact with SQLite via Fluent.
    try services.register(FluentPostgreSQLProvider())
    
    /// Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)
    
    /// Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    /// middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    services.register(middlewares)
    
    
   //Create a DatabasesConfig to configure the database
   var databases = DatabasesConfig()
        
    //Use Environment.get(_:) to fetch environment variable set by Vapor Cloud.
    //If the function call returns nil (i.e. the application is running locally), default to the values required for the Docker container.
    let hostname = Environment.get("DATABASE_HOSTNAME") ?? "localhost"
    let username = Environment.get("DATABASE_USER") ?? "vapor"
    let databaseName = Environment.get("DATABASE_DB") ?? "vapor"
    let password = Environment.get("DATABASE_PASSWORD") ?? "password"
    
    //Use the properties to create a new PostgreSQLDatabaseConfig
    let databaseConfig = PostgreSQLDatabaseConfig(hostname: hostname, username: username, database: databaseName, password: password)
        
    //Create a PostgreSQLDatabase using the configuration
    let database = PostgreSQLDatabase(config: databaseConfig)
 
    //Add the database object to the DatabasesConfig using the default .psql identifier.
    databases.add(database: database, as: .psql)
    
    //Register DatabasesConfig with the services.
    services.register(databases)
        
        
    
    /// Configure migrations
    // Tells the application which database to use for each model.
    var migrations = MigrationConfig()

    //Add the model to the mgrations to Fluent prepares the table in the database at the next application start.
    migrations.add(model: User.self, database: .psql)

    migrations.add(model: Acronym.self, database: .psql)

    //Add a new model to the MigrationConfig, so that Fluent creates the table in the database at the next application start.
    migrations.add(model: Category.self, database: .psql)

    //Add the pivot model to the MigrationConfig so that Fluent prepares the table in the database at the next application start.
    migrations.add(model: AcronymCategoryPivot.self, database: .psql)
        
        
    services.register(migrations)
    
    //Create a CommandConfig with the default configuration
    var commandConfig = CommandConfig.default()
    //Add the Fluent commands to your CommandConfig.
    //This adds both the revert command with the identifier revert and the migrate command with the identifier migrate.  You use these strings to invoke the commands.
    commandConfig.useFluentCommands()
    //Register the commandCondig as a service.
    services.register(commandConfig)
        
        
    
}

