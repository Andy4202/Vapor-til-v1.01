import Vapor
import Fluent

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    // Basic "Hello, world!" example
    router.get("hello") { req in
        return "Hello, world!"
    }
    
    
    // 1.  Register a new route at /api/acronyms that accepts a POST request and returns Future<Acronym>
    //      It returns the acronym once it's saved.
    router.post("api", "acronyms") { req -> Future<Acronym> in
        // 2.
        // Decode the request's JSON into an Acronym model using Codable.
        // This returns a Future<Acronym> so it uses a flatMap(to:) to extract the acronym when the decoding is complete.  decode(_:) returns a Future<Acronym>
        return try req.content.decode(Acronym.self).flatMap(to: Acronym.self) { acronym in
            
            // 3. Save the model using Fluent.  This returns Future<Acronym> as it returns the model onces it's saved.
            return acronym.save(on: req)
        }
    }
    
    // 1. Register a new route handler for the request which returns Future<[Acronym]>,
    //      a future array of acronyms.
    router.get("api", "acronyms") { req -> Future<[Acronym]> in
        // 2. Perform a query to get all the acronyms.
        return Acronym.query(on: req).all()
        
    }
    
    // 1. Register a route at /api/acronyms/<ID> to handle a GET request.
    //  This route takes the acronym's id property as the final path segment.
    //  This returns Future<Acronym>.
    router.get("api", "acronyms", Acronym.parameter) {
        req -> Future<Acronym> in
        // 2. Extract the acronym from the request using the parameter function.
        //      This function performs all the work necessary to get the acronym from the database.
        //      It also handles the error cases when the acronym does not exist, ot the ID type is wrong,
        //      for example, when you pass it an integer when the ID is a UUID.
        return try req.parameters.next(Acronym.self)
    }
    
    
    // 1. Register a route for a PUT request to /api/acronyms/<ID>
    router.put("api", "acronyms", Acronym.parameter) { req -> Future<Acronym> in
        // 2. Use flatMap(to:_:_:), the dual future form of flatMap, to wait for both the parameter
        //  extraction and content decoding to complete. This provides both the acronym from the database and acronym from the request body to the closure.
        return try flatMap(to: Acronym.self,
                            req.parameters.next(Acronym.self),
                            req.content.decode(Acronym.self)) {
                                acronym, updatedAcronym in
        // 3. Update the acronym's properties with the new values.
        acronym.short = updatedAcronym.short
        acronym.long = updatedAcronym.long
                                
        // 4. Save the acronym and return the result.
        return acronym.save(on: req)
                                
        }
    }
    
    
    // 1.
    // Register a route for a DELETE request to /api/acronyms/<ID> that returns Future<HTTPStatus>
    router.delete("api", "acronyms", Acronym.parameter) {
        req -> Future<HTTPStatus> in
        // 2.
        // Extract the acronym to delete from the request's parameters.
        return try req.parameters.next(Acronym.self)
        // 3.
            // Delete the acronym using delete(on:).
            // Instead of requiring you to unwrap the returned Future, Fluent allows you to call
            // delete(on:) directly on that Future.  This helps tidy up code and reduce nesting.
            //Fluent provides convenience functions for delete, update, create and save.
        .delete(on: req)
        // 4.
        // Transform the result into a 204 No Content response.
        // This tells the client the request has successfully completed but there's no content to return.
        .transform(to: HTTPStatus.noContent)
        
    }
    
    

    router.get("api", "acronyms", "search") { req -> Future<[Acronym]> in
        guard
            let searchTerm = req.query[String.self, at: "term"] else {
                throw Abort(.badRequest)
        }
        
        //Create a filter group using the .or relation.
        return Acronym.query(on: req).group(.or) { or in
           //Looking for the short property.
           or.filter(\.short == searchTerm)
           // Looking for the long property.
           or.filter(\.long == searchTerm)
        //Return all the results.
        }.all()
    }
    
    // Register a new HTTP GET route for /api/acronyms/first that returns Future<Acronym>
    router.get("api", "acronyms", "first") {
        req -> Future<Acronym> in
        
        // Perform a query to get the first acronym.
        // Use the map(to:) function to unwrap the result of the query.
        return Acronym.query(on: req)
        
        .first()
        .map(to: Acronym.self) { acronym in
            //Ensure an acronym exists
            //.first() returns an optional as there may be no acronyms in the database.
            guard let acronym = acronym else {
                throw Abort(.notFound)
            }
            return acronym
        }
    }
    
    // Register a new HTTP GET route for /api/acronyms/sorted that returns Future<[Acronym]>
    router.get("api", "acronyms", "sorted") {
        req -> Future<[Acronym]> in
        // Create a query for Acronym and use sort(_:_:) to perform the sort.
        // This function takes the field to sort on and the direction to sort in.
        return Acronym.query(on: req)
        .sort(\.short, .ascending)
        .all() // Return all the queries.
    }
    
}
