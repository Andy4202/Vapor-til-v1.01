import Vapor
import Crypto



struct UsersController: RouteCollection {
    
    func boot(router: Router) throws {
        
        //Create a new route group for the path /api/users/
        let usersRoute = router.grouped("api", "users")
        
        //Register createHandler(_:) to handle a POST request to /api/users.
        //This uses the POST helper method to decode the request body into a User object.
        //usersRoute.post(User.self, use: createHandler)
        
        usersRoute.get(use: getAllHandler)
        
        usersRoute.get(User.parameter, use: getHandler)
        
        //Register getAcronymsHandler
        //This connects an HTTP GET request to /api/users/<USER ID>/acronyms to getAcronymsHandler(_:)
        usersRoute.get(User.parameter, "acronyms", use: getAcronymsHandler)
        
        //Create a protected route group using HTTP basic authentication, as you did for creating an acronym.
        // This doesn't use GuardAuthenticationMiddleware since requireAuthenticated(_:) throws the correct error if a user isn't authenticated.
        let basicAuthMiddleware = User.basicAuthMiddleware(using: BCryptDigest())
        let basicAuthGroup = usersRoute.grouped(basicAuthMiddleware)
        
        // Connect /api/users/login to loginHandler(_:) through the protected group.
        basicAuthGroup.post("login", use: loginHandler)
        
        let tokenAuthMiddleware = User.tokenAuthMiddleware()
        let guardAuthMiddleware = User.guardAuthMiddleware()
        let tokenAuthGroup = usersRoute.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        tokenAuthGroup.post(User.self, use: createHandler)
        
        
    }
    
    //Define a route handler function.
    func createHandler(_ req: Request, user: User) throws -> Future<User.Public> {
        
        //Hash the user's password before saving it in the database.
        user.password = try BCrypt.hash(user.password)
        
        //Save the decoded user from the request.
        return user.save(on: req).convertToPublic()
    }
    
    
    //These next two functions return a list of all users and a single user.
    //Process GET request to /api/users/
    func getAllHandler(_ req: Request) throws -> Future<[User.Public]> {
        return User.query(on: req).decode(data: User.Public.self).all()
    }
    
    //Process GET requests to /api/users/<USER ID>
    func getHandler(_ req: Request) throws -> Future<User.Public> {
        return try req.parameters.next(User.self).convertToPublic()
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
    
    //Route handler for logging a user in.
    func loginHandler(_ req: Request) throws -> Future<Token> {
        // Get the authenticated user form the request.
        // You'll protect this route with the HTTP basic authentication middleware.
        // This saves the user's identity in the request's authentication cache, allowing you to retrieve the user object later.
        // requireAuthenticated(_:) throws an authentication error if there's no authenticated user.
        let user = try req.requireAuthenticated(User.self)
        // Create a token for the user.
        let token = try Token.generate(for: user)
        // Save and return the token.
        return token.save(on: req)
    }
    
}
