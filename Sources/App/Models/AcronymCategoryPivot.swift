import FluentPostgreSQL
import Foundation
import Vapor

/*
 Define a new object AcronymCategoryPivot that conforms to PostgreSQLUUIDPivot.
 This is a helper protocol on top of Fluent's Pivot protocol.
 Also conform to ModifiablePivot.
 This allows you to use the syntactice sugar Vapor provides for adding and removing relationships.
*/
final class AcronymCategoryPivot: PostgreSQLUUIDModel,  ModifiablePivot {
    
    //Define an id for the model.
    //Note this is a UUID type so you must import the Foundation module.
    var id: UUID?
    
    //Define two properties to link to the IDs of Acronym and Category.
    //This is what hold the relationship.
    var acronymID: Acronym.ID
    var categoryID: Category.ID
    
    //Define the Left and Right types requires by Pivot.
    //This tells Fluent what the two models in the relationship are.
    typealias Left = Acronym
    typealias Right = Category
    
    //Tell Fluent the key path of the two ID properties for each side of the relationship.
    static let leftIDKey: LeftIDKey = \.acronymID
    static let rightIDKey: RightIDKey = \.categoryID
    
    //Implement the throwing initializer, as required by ModifiablePivot.
    init(_ acronym: Acronym, _ category: Category) throws {
        self.acronymID = try acronym.requireID()
        self.categoryID = try category.requireID()
    }
}

// Conform to Migration so Fluent can set up the table.
//extension AcronymCategoryPivot: Migration {}

extension AcronymCategoryPivot: Migration {
    
    //Implement prepare(on:) as defined by Migration.
    //This overrides the default implementation.
    static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
        //Create the table for AcronymCategoryPivot in the database.
        return Database.create(self, on: connection) { builder in
            //Use addProperties(to:) to add all the fields to the database.
            try addProperties(to: builder)
            /*
            Add a reference between the acronymID property on AcronymCategoryPivot and the id property
             on Acronym.  This sets up the FK constraint.
             .cascase sets a cascade schema reference action when you delete the acronym.
             This means that the relationship is automatically removed instead of an error being thrown.
            */
            builder.reference(from: \.acronymID, to: \Acronym.id, onDelete: .cascade)
            
            /*
            Add a reference between the category property on AcronymCategoryPivot and the id property
            on Category.  This sets up the FK constraint.
             Also set the schema reference action for deletion when deleting the category.
            */
            builder.reference(from: \.categoryID, to: \Category.id, onDelete: .cascade)
            
            
        }
    }
}
