import Vapor
import FluentPostgreSQL

final class Category: Codable {
    
    //Stores the ID of the model when it's set.
    var id: Int?
    //String to hold the categories name.
    var name: String
    
    init(name: String) {
        self.name = name
    }
}

extension Category: PostgreSQLModel {}
extension Category: Content {}
extension Category: Migration {}
extension Category: Parameter {}


extension Category {
    //Add a computed property to Category to get its acronyms.
    //This returns Fluent's generic Sibling type.
    //It returns the siblings of a Category that are of type Acronym and held using the AcronymCategoryPivot.
    var acronyms: Siblings<Category, Acronym, AcronymCategoryPivot> {
        //User Fluent's siblings() function to retrieve all the acronyms.
        //Fluent handles everything else.
        return siblings()
    }
}
