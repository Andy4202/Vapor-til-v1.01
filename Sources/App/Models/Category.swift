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
    
    static func addCategory(_ name: String, to acronym: Acronym, on req: Request) throws -> Future<Void>
    {
        // Perform a query to search for a category with the provided name.
        return Category.query(on: req)
            .filter(\.name == name)
            .first()
            .flatMap(to: Void.self) { foundCategory in
                if let existingCategory = foundCategory {
                    // If the category exists, set up the relationship and transform to result to Void.
                    //() is shorthand for Void().
                    return acronym.categories
                        .attach(existingCategory, on: req)
                        .transform(to: ())
                } else { // If the category doesn’t exist, create a new Category object with the provided name.
                    let category = Category(name: name)
                    // Save the new category and unwrap the returned future.
                    return category.save(on: req)
                        .flatMap(to: Void.self) { savedCategory in
                            // Set up the relationship and transform the result to Void.
                            return acronym.categories
                                .attach(savedCategory, on: req)
                                .transform(to: ())
                    }
                }
        }
        
    }
    
    
    
    
    
    //Add a computed property to Category to get its acronyms.
    //This returns Fluent's generic Sibling type.
    //It returns the siblings of a Category that are of type Acronym and held using the AcronymCategoryPivot.
    var acronyms: Siblings<Category, Acronym, AcronymCategoryPivot> {
        //User Fluent's siblings() function to retrieve all the acronyms.
        //Fluent handles everything else.
        return siblings()
    }
}
