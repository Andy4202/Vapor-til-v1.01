import FluentPostgreSQL
import Vapor

// 1. Define a new type, MakeCategoriesUnique, that conforms to Migration.
struct MakeCategoriesUnique: Migration {
    // 2. As required by Migration, define your database type with a typealias.
    typealias Database = PostgreSQLDatabase
    
    // 3. Define the required prepare(on:)
    static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
        // 4. Since Category already exists in your database, use update(_:on:closure:) to modify the database.
        return Database.update(Category.self, on: connection) { builder in
            // 5. Inside the closure, use unique(on:) to add a new unique index corresponding to the key path \.name.
            builder.unique(on: \.name)
        }
    }
    
    // 6. Define required revert(on:)
    static func revert(on connection: PostgreSQLConnection) -> Future<Void> {
        // 7. Since you're modifying an existing Model, you again use update(_:on:closure:) to remove the new index.
        return Database.update(Category.self, on: connection) { builder in
            // 8. Inside the closure, use deleteUnique(from:) to remove the index corresponding to the key path \.name.
            builder.deleteUnique(from: \.name)
            
        }
    }
}
