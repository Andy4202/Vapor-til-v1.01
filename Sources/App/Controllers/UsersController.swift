import Vapor



struct UsersController: RouteCollection {
    
    func boot(router: Router) throws {
        
        //Create a new route group for the path /api/users/
        let usersRoute = router.grouped("api", "users")
        
        //Register createHandler(_:) to handle a POST request to /api/users.
        //This uses the POST helper method to decode the request body into a User object.
        usersRoute.post(User.self, use: createHandler)
        
        usersRoute.get(use: getAllHandler)
        
        usersRoute.get(User.parameter, use: getHandler)
        
        //Register getAcronymsHandler
        //This connects an HTTP GET request to /api/users/<USER ID>/acronyms to getAcronymsHandler(_:)
        usersRoute.get(User.parameter, "acronyms", use: getAcronymsHandler)
    }
    
    //Define a route handler function.
    func createHandler(_ req: Request, user: User) throws -> Future<User> {
        //Save the decoded user from the request.
        return user.save(on: req)
        
    }
    
    
    //These next two functions return a list of all users and a single user.
    //Process GET request to /api/users/
    func getAllHandler(_ req: Request) throws -> Future<[User]> {
        return User.query(on: req).all()
    }
    
    //Process GET requests to /api/users/<USER ID>
    func getHandler(_ req: Request) throws -> Future<User> {
        return try req.parameters.next(User.self)
    }
    
    //Route handler that returns Future<[Acronym]>
    func getAcronymsHandler(_ req: Request) throws -> Future<[Acronym]> {
        //Fetch the user specified in the request's parameters and unwrap the returned future.
        return try req.parameters.next(User.self)
            .flatMap(to: [Acronym].self) { user in
                //Use the computed property in User.swift, acronyms, to get the acronyms using a Fluent query to return all the acronyms.
                try user.acronyms.query(on: req).all()
                
        }
    }
}
