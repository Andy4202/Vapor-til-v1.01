import Vapor
//import Leaf

// Declare a new WebsiteController type that conforms to RouteCollection.
// RouteCollection: Groups collections of routes together for adding to a router.
struct WebsiteController: RouteCollection {

    // Implement boot(router:) as required by RouteCollection
    func boot(router: Router) throws {
        //Register indexHandler(_:) to process GET requests to the router's root path,
        //      i.e a request to /.
        router.get(use: indexHandler)
        
        //Register acronynHandler route for /acronyms/<ACRONYM ID> similar to the API.
        router.get("acronyms", Acronym.parameter, use: acronymHandler)

    }
    // Implement indexHandler(_:) that returns Future<View>
    func indexHandler(_ req: Request) throws -> Future<View> {
        
        //Use a Fluent query to get all the acronyms from the database.
        return Acronym.query(on: req)
            .all()
            .flatMap(to: View.self) { acronyms in
                // Add the acronyms to IndexContext if there are any,
                // otherwise set the variable to nil.
                // This is easier for Leaf to manage than an empty array.
                let acronymData = acronyms.isEmpty ? nil : acronyms
                let context = IndexContext(title: "Homepage",
                                           acronyms: acronymData)
                
                return try req.view().render("index", context)
                
                
        }
    }
    
    // Declare a new route handler, acronymHandler(_:), that returns Future<View>
    func acronymHandler(_ req: Request) throws -> Future<View> {
        
        //Extract the acronym from the request's parameters and unwrap the result.
        return try req.parameters.next(Acronym.self)
            .flatMap(to: View.self) { acronym in
                //Get the user for acronym and unwrap the result.
                return acronym.user
                    .get(on: req)
                    .flatMap(to: View.self) { user in
                        //Create an AcronymContext that contains the appropriate details and render the page using the acronym.leaf template.
                        let context = AcronymContext(title: acronym.short, acronym: acronym, user: user)
                        return try req.view().render("acronym", context)
                        
                }
        }
    }
}

//IndexContent is the data for your view, similar to a view model in the MVVM design pattern.
struct IndexContext: Encodable {
    //Properties to be displayed on the website.
    let title: String
    //Optional - it can be nil as there may be no acronyms in the database.
    let acronyms: [Acronym]?
}


//Type to hold the context of acronym page.
struct AcronymContext: Encodable {
    //Title for the page.
    let title: String
    let acronym: Acronym
    //User who created the acronym.
    let user: User
}

