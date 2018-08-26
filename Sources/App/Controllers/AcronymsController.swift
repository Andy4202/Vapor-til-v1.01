import Vapor
import Fluent
import Authentication

struct AcronymsController: RouteCollection {
    
    func boot(router: Router) throws {
        
        //This creates a new route group for the path /api/acronyms
        let acronymsRoutes = router.grouped("api", "acronyms")
        
        //Register the route...
        //router.get("api", "acronyms", use: getAllHandler)
        
        acronymsRoutes.get(use: getAllHandler)
        
//        func createHandler(_ req: Request) throws -> Future<Acronym> {
//            return try req
//                .content
//                .decode(Acronym.self)
//                .flatMap(to: Acronym.self) { acronym in
//                    return acronym.save(on: req)
//            }
//        }
        
        //The acronym parameter is the decoded acronym from the request,
        //  so you don't have to decode the data yourself.
//        func createHandler(_ req: Request, acronym: Acronym) throws -> Future<Acronym> {
//            return acronym.save(on: req)
//        }

        
        // Define a route handler that accepts AcronymCreateData as the request body.
        func createHandler(_ req: Request, data: AcronymCreateData) throws -> Future<Acronym> {
            // Get the authenticated user from the request.
            let user = try req.requireAuthenticated(User.self)
            //Create a new Acronym using the data from the request and the authenticated user.
            let acronym = try Acronym(short: data.short, long: data.long, userID: user.requireID())
            //Save and return the acronym.
            return acronym.save(on: req)
        }
        
        
        func getHandler(_ req: Request) throws -> Future<Acronym> {
            return try req.parameters.next(Acronym.self)
        }
        
//        func updateHandler(_ req: Request) throws -> Future<Acronym> {
//            return try flatMap(to: Acronym.self,
//            req.parameters.next(Acronym.self),
//            req.content.decode(Acronym.self)) {
//                acronym, updatedAcronym in
//                    acronym.short = updatedAcronym.short
//                    acronym.long = updatedAcronym.long
//                    return acronym.save(on: req)
//            }
//        }

        
        //This updates the acronym's properties with the new values provided in the request.
        func updateHandler(_ req: Request) throws -> Future<Acronym> {
            
            //Decode the request's data to AcronymCreateData since request no longer contains the user's ID in the post data.
            return try flatMap(to: Acronym.self,
                               req.parameters.next(Acronym.self),
                               req.content.decode(AcronymCreateData.self)) {
                                acronym, updatedAcronym in
                                
                                acronym.short = updatedAcronym.short
                                acronym.long = updatedAcronym.long
                                //acronym.userID = updatedAcronym.userID
                                
                                // Get the authenticated user from the request and use that to update the acronym.
                                let user = try req.requireAuthenticated(User.self)
                                acronym.userID = try user.requireID()
                                return acronym.save(on: req)
            }
        }
        
        
        
        
        func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
            return try req
                .parameters
                .next(Acronym.self)
                .delete(on: req)
                .transform(to: HTTPStatus.noContent)
        }
        
        func searchHandler(_ req: Request) throws -> Future<[Acronym]> {
            guard let searchTerm = req
                .query[String.self, at: "term"] else {
                    throw Abort(.badRequest)
            }
            return Acronym.query(on: req).group(.or) { or in
                or.filter(\.short == searchTerm)
                or.filter(\.long == searchTerm)
                
            }.all()
        }
        
        func getFirstHandler(_ req: Request) throws -> Future<Acronym> {
            return Acronym.query(on: req)
            .first()
                .map(to: Acronym.self) { acronym in
                    guard let acronym = acronym else {
                        throw Abort(.notFound)
                    }
                    return acronym
            }
        }
        
        func sortedHandler(_ req: Request) throws -> Future<[Acronym]> {
            return Acronym.query(on: req).sort(\.short, .ascending).all()
        }
     
        //Define a new route handler, getUserHandler(_:), that returns Future<User>.
        func getUserHandler(_ req: Request) throws -> Future<User.Public> {
            //Fetch the acronym specified in the request's parameters and unwrap the returned future.
            return try req.parameters.next(Acronym.self)
                .flatMap(to: User.Public.self) { acronym in
                    //Use the new computed property created in the Acronym extension in Acronym.swift to get the acronym's owner.
                    acronym.user.get(on: req).convertToPublic()
                
            }
        }
        
        //Route handler that returns a Future<HTTPStatus>
        func addCategoriesHandler(_ req: Request) throws -> Future<HTTPStatus> {
            //Use flatMap(to:_:_) to extract both the acronym and category from the request's parameters.
            return try flatMap(to: HTTPStatus.self,
                                req.parameters.next(Acronym.self),
                                req.parameters.next(Category.self)) { acronym, category in
            //Use attach(_:on:) to set up the relationship between acronym and category.
            //This creates a pivot model and saves it in the database.
            //Transform the result into a 201 Created response.
                                    return acronym.categories
                                        .attach(category, on: req)
                                        .transform(to: .created)
                                    
            }
        }
        
        
        //Route handler returning Future<[Category]>
        func getCategoriesHandler(_ req: Request) throws -> Future<[Category]> {
            //Extract the acornym from the request's parameters and unwrap the returned future.
            return try req.parameters.next(Acronym.self)
                .flatMap(to: [Category].self) { acronym in
                    //Use the computed property to get the categories.
                    //Then use a Fluent query to return all the categories.
                    try acronym.categories.query(on: req).all()
                    
            }
        }
        
        
        //Define a new route handler, removeCategoriesHandler(_:), that returns a Future<HTTPStatus>
        func removeCategoriesHandler(_ req: Request) throws -> Future<HTTPStatus> {
            
            //Use flatMap(to:_:_:) to extract both the acronym and category from the request's parameters.
            return try flatMap(to: HTTPStatus.self, req.parameters.next(Acronym.self), req.parameters.next(Category.self)) { acronym, category in
                
                //Use detach(_:on:) to remove the relationship between acronym and category.
                //This finds the pivot model in the database and deletes it.
                // Transform the result into a 204 No Content response.
                return acronym.categories
                    .detach(category, on: req)
                    .transform(to: .noContent)
            }
        }
        
        
        
        //Register the route handlers using the route group.
        
        //Register createHandler(_:) to process POST requests to /api/acronyms
        //This helper function takes the type to decode as the first parameter.
        //You can provide any path components before the use: parameter, if required.
        //Below removed to remove the unauthenticated route of creating acronyms.
        //acronymsRoutes.post(Acronym.self, use: createHandler)
        
        
        //Register getHandler(_:) to process GET requests to /api/acronyms/<ACRONYM ID>
        acronymsRoutes.get(Acronym.parameter, use: getHandler)
        //Register updateHandler(_:) to process PUT requests to /api/acronyms/<ACRONYM ID>
        //acronymsRoutes.put(Acronym.parameter, use: updateHandler)
        //Register deleteHandler(_:) to process DELETE requests to /api/acronyms/<ACRONYM ID>
        //acronymsRoutes.delete(Acronym.parameter, use: deleteHandler)
        //Register searchHandler(_:) to process GET requests to /api/acronyms/search
        acronymsRoutes.get("search", use: searchHandler)
        //Register getFirstHandler(_:) to process GET requests to /api/acronyms/first
        acronymsRoutes.get("first", use: getFirstHandler)
        //Register sortedHandler(_:) to process GET requests to /api/acronyms/sorted
        acronymsRoutes.get("sorted", use: sortedHandler)
        
        //This connects an HTTP GET request to:
        //      /api/acronyms/<ACRONYM ID>/user
        // to getUserHandler(_:)
        acronymsRoutes.get(Acronym.parameter, "user", use: getUserHandler)
        
        //This routes an HTTP POST request to /api/acronyms/<ACRONYM ID>/categories/<CATEGORY ID>
        // to addCategoriesHandler(_:)
        //acronymsRoutes.post(Acronym.parameter, "categories", Category.parameter, use: addCategoriesHandler)
        
        //This routes an HTTP GET request to /api/acronyms/<ACRONYM ID>/categories to getCategoriesHandler(:_)
        acronymsRoutes.get(Acronym.parameter, "categories", use: getCategoriesHandler)
        
        
        //This routes an HTTP DELETE request to /api/acronyms/<ACRONYM_ID>/categories/<CATEGORY_ID>
        //  to removeCategoriesHandler(_:)
        //acronymsRoutes.delete(Acronym.parameter, "categories", Category.parameter, use: removeCategoriesHandler)
        
        
//        // Instantiate a basic authentication middleware which uses BCryptDigest to verify passwords.
//        // Since User conforms to BasicAuthenticatable, this is available as a static function on the model.
//        let basicAuthMiddleware = User.basicAuthMiddleware(using: BCryptDigest())
//
//        // Create an instance of GuardAuthenticationMiddleware which ensures that requests contain valid authorization.
//        let guardAuthMiddleware = User.guardAuthMiddleware()
//
//        // Create a middleware group which uses basicAuthMiddleware and guardAuthMiddleware
//        let protected = acronymsRoutes.grouped(basicAuthMiddleware, guardAuthMiddleware)
//
//        // Connect the "create acronym" path to createHandler(_:acronym:) through this middleware group.
//        protected.post(Acronym.self, use: createHandler)
        

        //The above statements are replaced with the following:
        
        // Create a TokenAuthenticationMiddleware for User.
        // This uses BearerAuthenticationMiddleware to extract the bearer token out of the request.
        // The middleware then converts this token into a logged in user.
        let tokenAuthMiddleware = User.tokenAuthMiddleware()
        let guardAuthMiddleware = User.guardAuthMiddleware()
        
        //Create a route group using tokenAuthMiddleware and guardAuthMiddleware to protect the route for creating an acronym with token authentication.
        let tokenAuthGroup = acronymsRoutes.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        
        // Connect the "create acronym" path to createHandler(_:data:) through this middleware group using the new AcronymCreateData.
        tokenAuthGroup.post(AcronymCreateData.self, use: createHandler)
        
        //These ensure that only authenticated users can create, edit and delete acronyms and add categories to acronyms. Unauthenticated users can still view details about acronyms.
        tokenAuthGroup.delete(Acronym.parameter, use: deleteHandler)
        tokenAuthGroup.put(Acronym.parameter, use: updateHandler)
        tokenAuthGroup.post(Acronym.parameter, "categories", Category.parameter, use: addCategoriesHandler)
        
        tokenAuthGroup.delete(Acronym.parameter, "categories", Category.parameter, use: removeCategoriesHandler)
        
    }
    
    func getAllHandler(_ req: Request) throws -> Future<[Acronym]> {
        return Acronym.query(on: req).all()
    }
}

//Define the request data that a user now has to send to create an acronym.
struct AcronymCreateData: Content {
    let short: String
    let long: String
}
