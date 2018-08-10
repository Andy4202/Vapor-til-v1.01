import Vapor
import FluentSQLite

final class Acronym: Codable {
    
    var id: Int?
    var short: String
    var long: String
    
    init(short: String, long: String) {
        self.short = short
        self.long = long
        
    }
}

//extension Acronym: Model {
//    // 1
//    // Tell Fluent what database to use for this model.
//    // The template is already configured to use SQLite.
//    typealias Database = SQLiteDatabase
//
//    // 2
//    // Tell Fluent what type the ID is.
//    typealias ID = Int
//
//    // 3
//    // Tell Fluent the key path of the model's ID property.
//    public static var idKey: IDKey = \Acronym.id
//}

//The above can be improved with SQLiteModel:
extension Acronym: SQLiteModel {}


/*
 To save the model in the database, you must create a table for it.
 Fluent does this with a migration.
 Migrations allow you to make reliable, testable, reproductive changes to your database.
 They are commonly used to create a database schema, or table description, for your models.
 They are also used to seed data into your database or make changes to your models after they've been saved.
 */
extension Acronym: Migration {}

//Content is a wrapper around Codable.
extension Acronym: Content {}
