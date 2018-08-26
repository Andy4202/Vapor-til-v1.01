@testable import App
import FluentPostgreSQL
import Crypto

extension User {
//    static func create(name: String = "Luke", username: String = "lukes", on connection: PostgreSQLConnection) throws -> User {
//        let user = User(name: name, username: username)
//        return try user.save(on: connection).wait()
//    }

    //Make the username parameter an optional string that defaults to nil.
    static func create(name: String = "Luke",
                       username: String? = nil,
                       on connection: PostgreSQLConnection) throws -> User {
        
        var createUsername: String
        
        // If a username is supplied, use it.
        if let suppliedUsername = username {
            createUsername = suppliedUsername
        } else {
            //If a username isn't supplied, create a new, random one using UUID.
            // This ensures the username is unique as required by the migration.
            createUsername = UUID().uuidString
        }
        //Create a user.
        let password = try BCrypt.hash("password")
        let user = User(name: name, username: createUsername, password: password)
        return try user.save(on: connection).wait()
    }



}

extension Acronym {
    static func create(short: String = "TIL", long: String = "Today I Learned", user: User? = nil, on connection: PostgreSQLConnection) throws -> Acronym {
        var acronymsUser = user
        
        if acronymsUser == nil {
            acronymsUser = try User.create(on: connection)
        }
        
        let acronym = Acronym(short: short, long: long, userID: acronymsUser!.id!)
        return try acronym.save(on: connection).wait()
    }
}


extension App.Category {
    static func create(name: String = "Random", on connection: PostgreSQLConnection) throws -> App.Category {
        let category = Category(name: name)
        return try category.save(on: connection).wait()
    }
}
