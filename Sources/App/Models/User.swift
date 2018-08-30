import Foundation
import Vapor
import FluentPostgreSQL
import Authentication

final class User: Codable {
    
    var id: UUID?
    var name: String
    var username: String
    var password: String
    var twitterURL: String?
    
    init(name: String, username: String, password: String, twitterURL: String? = nil) {
        self.name = name
        self.username = username
        self.password = password
        self.twitterURL = twitterURL
    }
    
    final class Public: Codable {
        var id: UUID?
        var name: String
        var username: String
        var twitterURL: String?
        
        init(id: UUID?, name: String, username: String, twitterURL: String? = nil) {
            self.id = id
            self.name = name
            self.username = username
            self.twitterURL = twitterURL
            
        }
    }
}

extension User: PostgreSQLUUIDModel {}
extension User: Content {}
//extension User: Migration {}

extension User: Migration {
    static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
        // Create the User table.
        return Database.create(self, on: connection) { builder in
            //Add all the columns to the User table using User's properties.
            //try addProperties(to: builder)
            
            builder.field(for: \.id, isIdentifier: true)
            builder.field(for: \.name)
            builder.field(for: \.username)
            builder.field(for: \.password)
            
            //Add a unique index to username on User.
            builder.unique(on: \.username)
        }
    }
}


extension User: Parameter {}

//This conforms User.Public to Content.
//Allowing you to return the public view in responses.
extension User.Public: Content {}

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


extension User {
    // Define a method on User that returns User.Public
    func convertToPublic() -> User.Public {
        // Create a public version of the current object.
        return User.Public(id: id, name: name, username: username, twitterURL: twitterURL)
    }
}

// Define an extension for Future<User>
extension Future where T: User {
    // Define a new method that returns a Future<User.Public>
    func convertToPublic() -> Future<User.Public> {
        // Unwrap the user contained in self.
        return self.map(to: User.Public.self) { user in
            // Convert the User object to User.Public
            return user.convertToPublic()
        }
    }
}

//Conform User to BasicAuthenticatable.
extension User: BasicAuthenticatable {
    // Tell Vapor which property of User is the username.
    static let usernameKey: UsernameKey = \User.username
    // Tell Vapor which property of User is the password.
    static let passwordKey: PasswordKey = \User.password
}

//Conform User to TokenAuthenticatable. This allows a token to authenticate a user.
extension User: TokenAuthenticatable {
    // Tell Vapor what type a token is.
    typealias TokenType = Token
}


// Define a new type that conforms to Migration.
struct AdminUser: Migration {
    // Define which database type this migration is for.
    typealias Database = PostgreSQLDatabase

    //Implement the required prepare(on:)
    static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
        // Create a password hash and terminate with a fatal error if this fails.
        let password = try? BCrypt.hash("password")
        guard let hashedPassword = password else {
            fatalError("Failed to create admin user")
        }
        // Create a new user with the name Admin, username admin and the hashed password.
        let user = User(name: "Admin", username: "admin", password: hashedPassword)
        // Save the user and transform to result to Void, the return type of prepare(on:)
        return user.save(on: connection).transform(to: ())
        
    }
    // Implement the required revert(on:)    .done(on:) returns a pre-completed Future<Void>
    static func revert(on connection: PostgreSQLConnection) -> Future<Void> {
        return .done(on: connection)
    }
}

/*
    Conform User to PasswordAuthenticatable.
    This allows Vapor to authenticate users with a username and password when they log in.
    Since you've already implemented the necessary properties for PasswordAuthenticatable in BasicAuthenticatable (above), there's nothing to do here.
 */
extension User: PasswordAuthenticatable {}


/*
    Conform User to SessionAuthenticatable.
    This allows the application to save and retrieve your user as part of a session.
 */
extension User: SessionAuthenticatable {}

