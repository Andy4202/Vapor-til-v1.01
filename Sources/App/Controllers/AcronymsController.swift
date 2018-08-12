import Vapor
import Fluent

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
        func createHandler(_ req: Request, acronym: Acronym) throws -> Future<Acronym> {
            return acronym.save(on: req)
        }
        
        
        func getHandler(_ req: Request) throws -> Future<Acronym> {
            return try req.parameters.next(Acronym.self)
        }
        
        func updateHandler(_ req: Request) throws -> Future<Acronym> {
            return try flatMap(to: Acronym.self,
            req.parameters.next(Acronym.self),
            req.content.decode(Acronym.self)) {
                acronym, updatedAcronym in
                    acronym.short = updatedAcronym.short
                    acronym.long = updatedAcronym.long
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
     
        
        //Register the route handlers using the route group.
        
        //Register createHandler(_:) to process POST requests to /api/acronyms
        //This helper function takes the type to decode as the first parameter.
        //You can provide any path components before the use: parameter, if required.
        acronymsRoutes.post(Acronym.self, use: createHandler)
        //Register getHandler(_:) to process GET requests to /api/acronyms/<ACRONYM ID>
        acronymsRoutes.get(Acronym.parameter, use: getHandler)
        //Register updateHandler(_:) to process PUT requests to /api/acronyms/<ACRONYM ID>
        acronymsRoutes.put(Acronym.parameter, use: updateHandler)
        //Register deleteHandler(_:) to process DELETE requests to /api/acronyms/<ACRONYM ID>
        acronymsRoutes.delete(Acronym.parameter, use: deleteHandler)
        //Register searchHandler(_:) to process GET requests to /api/acronyms/search
        acronymsRoutes.get("search", use: searchHandler)
        //Register getFirstHandler(_:) to process GET requests to /api/acronyms/first
        acronymsRoutes.get("first", use: getFirstHandler)
        //Register sortedHandler(_:) to process GET requests to /api/acronyms/sorted
        acronymsRoutes.get("sorted", use: sortedHandler)
        
    }
    
    func getAllHandler(_ req: Request) throws -> Future<[Acronym]> {
        return Acronym.query(on: req).all()
    }

    
    
}
