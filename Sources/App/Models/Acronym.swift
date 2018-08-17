import Vapor
import FluentPostgreSQL

final class Acronym: Codable {
    
    var id: Int?
    var short: String
    var long: String
    var userID: User.ID
    

    
    
    
    init(short: String, long: String, userID: User.ID) {
        self.short = short
        self.long = long
        self.userID = userID
        
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
//extension Acronym: SQLiteModel {}
extension Acronym: PostgreSQLModel {}


/*
 To save the model in the database, you must create a table for it.
 Fluent does this with a migration.
 Migrations allow you to make reliable, testable, reproductive changes to your database.
 They are commonly used to create a database schema, or table description, for your models.
 They are also used to seed data into your database or make changes to your models after they've been saved.
 */
//extension Acronym: Migration {}





//Content is a wrapper around Codable.
extension Acronym: Content {}

//Vapor's powerful type safety for parameters extends to models that conform to Parameter.
extension Acronym: Parameter {}

//extension to get the acronym's parent:
extension Acronym {
    // Add a computed property to Acronym to get the User object of the acronym's owner.
    // This returns Fluent's generic Parent type.
    var user: Parent<Acronym, User> {
        //Use Fluent's parent(_:) function to retrieve the parent.
        //This takes the key path of the user reference on the acronym.
        return parent(\.userID)
    }
    
    
    /*
     Add a computed property to Acronym to get an acronym's categories.
     This returns Fluent's generic Sibling type.
     It returns the siblings of an Acronym that are of type Category and held using the
     AcronymCategoryPivot.
     */
    var categories: Siblings<Acronym, Category, AcronymCategoryPivot> {
        // Use Fluent's siblings() function to retrieve all the categories.
        // Fluent handles everything else.
        return siblings()
        
    }
    
}



//Conform Acronym to Migration
extension Acronym: Migration {
    //Implement prepare(on:) as required by Migration.
    //This overrides the default implementation.
    static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
        //Create the table for Acronym in the database.
        return Database.create(self, on: connection) { builder in
            //Use addProperties(to:) to add all the fields to the database.
            //This means you don't need to add each column manually.
            try addProperties(to: builder)
            //Add a reference between the userID property on Acronym and the id property on User.
            //This sets up the foreign key constraint between the two tables.
            builder.reference(from: \.userID, to: \User.id)
            
        }
    }
}

