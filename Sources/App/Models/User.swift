import Foundation
import Vapor
import FluentPostgreSQL

final class User: Codable {
    
    var id: UUID?
    var name: String
    var username: String
    
    init(name: String, username: String) {
        self.name = name
        self.username = username
    }
    
}

extension User: PostgreSQLUUIDModel {}
extension User: Content {}
extension User: Migration {}
extension User: Parameter {}

//To get the user's acronyms.
extension User {
    // Add a computed property to User to get a user's acronyms.
    // This returns Fluent's generic Children type.
    var acronyms: Children<User, Acronym> {
        // Use Fluent's children(_:) function to retrieve the children.
        // This takes the key path of the user reference on the acronym.
        return children(\.userID)
    }
}
