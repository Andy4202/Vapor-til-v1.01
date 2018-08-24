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

        //Register userHandler for /users/<USER ID>
        router.get("users", User.parameter, use: userHandler)
        
        //Register allUsersHandler for /users/
        router.get("users", use: allUsersHandler)
        
        //Register a route at /categories that accepts GET requests and calls allCategoriesHandler(_:).
        router.get("categories", use: allCategoriesHandler)
        //Register a route at /categories/<CATEGORY ID> that accepts GET requests and calls categoryHandler(_:)
        router.get("categories", Category.parameter, use: categoryHandler)
        
        //Register a route at /acronyms/create that accepts GET requests and calls createAcronymHandler(_:)
        router.get("acronyms", "create", use: createAcronymHandler)
        //Register a route at /acronyms/create that accepts POST requests and calls
        //  createAcronymPostHandler(_:acronym:).  This also decodes the request's body to an Acronym.
        //router.post(Acronym.self, at: "acronyms", "create", use: createAcronymPostHandler)
        router.post(CreateAcronymData.self, at: "acronyms", "create", use: createAcronymPostHandler)
        
        //Register a route a /acronyms/<ACRONYM_ID>/edit to accept GET requests that calls editAcronymHandler(_:).
        router.get("acronyms", Acronym.parameter, "edit", use: editAcronymHandler)
        
        //Register a route to handle POST requests to the same URL that calls editAcronymPostHandler(_:)
        router.post("acronyms", Acronym.parameter, "edit", use: editAcronymPostHandler)
        
        //Register the delete route.
        //Registers a route at /acronyms/<ACRONYM ID>/delete to accept POST requests and call deleteAcronymHandler(_:).
        router.post("acronyms", Acronym.parameter, "delete", use: deleteAcronymHandler)
        
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
                        //let context = AcronymContext(title: acronym.short, acronym: acronym, user: user)
                        
                        let categories = try acronym.categories.query(on: req).all()
                        
                        let context = AcronymContext(title: acronym.short, acronym: acronym, user: user, categories: categories)
                        
                        return try req.view().render("acronym", context)
                        
                }
        }
    }
    
    
    //Define the route handler for the user page that returns Future<View>
    func userHandler(_ req: Request) throws -> Future<View> {
        
        //Get the user from the request's parameter and unwrap the future.
        return try req.parameters.next(User.self)
            .flatMap(to: View.self) { user in
                //Get the user's acronyms using the computer property and unwrap the future.
                return try user.acronyms
                    .query(on: req)
                    .all()
                    .flatMap(to: View.self) { acronyms in
                        /*
                        Create a UserContext, then render the user.leaf template, returning the result.
                         In this case, you're not setting the acronyms array to nil if it's empty.
                         This is not required as you're checking the count in template.
                        */
                        let context = UserContext(title: user.name, user: user, acronyms: acronyms)
                        return try req.view().render("user", context)
                        
                }
        }
    }
    
    
    //Define a route handler for the "All Users" page that returns Future<View>
    func allUsersHandler(_ req: Request) throws -> Future<View> {
        
        //Get the users from the database and unwrap the future.
        return User.query(on: req)
            .all()
            .flatMap(to: View.self) { users in
                //Create an AllUsersContext and render the allUsers.leaf template, then return the result.
                let context = AllUsersContext(title: "All Users", users: users)
                return try req.view().render("allUsers", context)
        }
    }
    
    func allCategoriesHandler(_ req: Request) throws -> Future<View> {
        //Create an AllCategoriesContext.
        //Notice that the context includes the query result directly, since Leaf can handle futures.
        let categories = Category.query(on: req).all()
        let context = AllCategoriesContext(categories: categories)
        //Render the allCategories.leaf template with the provided context.
        return try req.view().render("allCategories", context)
    }
    
    func categoryHandler(_ req: Request) throws -> Future<View> {
        //Get the category from the request's parameters and unwrap the returned future.
        return try req.parameters.next(Category.self)
            .flatMap(to: View.self) { category in
                //Create a query to get all the acronyms for the category.
                //This is a Future<[Acronym]>
                let acronyms = try category.acronyms.query(on: req).all()
                //Create a context for the page.
                let context = CategoryContext(title: category.name, category: category, acronyms: acronyms)
                
                //Return a rendered view using the category.leaf template.
                return try req.view().render("category", context)
        }
    }
    
    func createAcronymHandler(_ req: Request) throws -> Future<View> {
        // Create a context by passing in a query to get all of the users.
        let context = CreateAcronymContext(users: User.query(on: req).all())
        // Render the page using the createAcronym.leaf template.
        return try req.view().render("createAcronym", context)
    }
    
 
    //Declare a route handler that takes Acronym as a parameter.
    //Vapor automatically decodes the form data to an Acronym object.
//    func createAcronymPostHandler(_ req: Request, acronym: Acronym) throws -> Future<Response> {
//
//        //Save the provided acronym and unwrap the returned future.
//        return acronym.save(on: req).map(to: Response.self) {
//            acronym in
//            //Ensure that the ID has been set, otherwise throw a 500 Internal Server Error.
//            guard let id = acronym.id else {
//                throw Abort(.internalServerError)
//            }
//
//            //Redirect to the page for the newly created acronym.
//            return req.redirect(to: "/acronyms/\(id)")
//
//        }
//    }

    //Change the Content type of route handler to accept CreateAcronymData.
    func createAcronymPostHandler(_ req: Request, data: CreateAcronymData) throws -> Future<Response> {
        
        //Create an Acronym object to save as it's no longer passed into the route.
        let acronym = Acronym(short: data.short, long: data.long, userID: data.userID)
        
        //Call flatMap(to:) instead of map(to:) as you now return a Future<Response> in the closure.
        return acronym.save(on: req)
            .flatMap(to: Response.self) { acronym in
                guard let id = acronym.id else {
                    throw Abort(.internalServerError)
                }
                
                //Define an array of futures to store the save operations.
                var categorySaves: [Future<Void>] = []
                
                //Loop through all the categories provided to the request and add the results of
                //      Category.addCategory(_:to:on:) to the array.
                for category in data.categories ?? [] {
                    
                    try categorySaves.append(Category.addCategory(category, to: acronym, on: req))
                    
                }
                //Flatten the array to complete all the Fluent operations and transform the result to a Response.  Redirect the page to the new acronym's page.
                let redirect = req.redirect(to: "/acronyms/\(id)")
                return categorySaves.flatten(on: req)
                    .transform(to: redirect)
        }
    }
    
    
    
    
    
    
    //Route handler to show the edit acronym form:
    func editAcronymHandler(_ req: Request) throws -> Future<View> {
        //Get the acronym to edit from the request's parameter and unwrap the future.
        return try req.parameters.next(Acronym.self)
            .flatMap(to: View.self) { acronym in
                //Create a context to edit the acronym, passing in all the users.
                //let context = EditAcronymContext(acronym: acronym, users: User.query(on: req).all())
                
                let users = User.query(on: req).all()
                let categories = try acronym.categories.query(on: req).all()
                let context = EditAcronymContext(acronym: acronym, users: users, categories: categories)
                
                //Render the page using the createAcronym.leaf template, the same template used for the create page.
                return try req.view().render("createAcronym", context)
                
        }
    }
    
//    func editAcronymPostHandler(_ req: Request) throws -> Future<Response> {
//
//        // Use the convenience form of flatMap to get the acronym from the request's parameter,
//        //  decode the incoming data and unwrap both results.
//        return try flatMap(to: Response.self,
//                            req.parameters.next(Acronym.self),
//                            req.content.decode(Acronym.self)) {
//                                acronym, data in
//                                // Update the acronym with the new data.
//                                acronym.short = data.short
//                                acronym.long = data.long
//                                acronym.userID = data.userID
//                                // Save the result and unwrap the returned future.
//                                return acronym.save(on: req)
//                                    .map(to: Response.self) {
//                                        savedAcronym in
//                                        //Ensure the ID has been set, otherwise throw a 500 Internal Server error.
//                                        guard let id = savedAcronym.id else {
//                                            throw Abort(.internalServerError)
//                                        }
//                                        //Return a redirect to the updated acronym's page.
//                                        return req.redirect(to: "/acronyms/\(id)")
//                                }
//        }
//    }
    
    
    
    func editAcronymPostHandler(_ req: Request) throws -> Future<Response> {
        
        //Change the content type the request decodes to CreateAcronymData.
        return try flatMap(
            to: Response.self,
            req.parameters.next(Acronym.self),
            req.content.decode(CreateAcronymData.self)) {
               acronym, data in
               acronym.short = data.short
               acronym.long = data.long
               acronym.userID = data.userID
                //Use flatMap(to:) on save(on:) since the closure now returns a future.
               return acronym.save(on: req).flatMap(to: Response.self) { savedAcronym in
                     guard let id = savedAcronym.id else {
                            throw Abort(.internalServerError)
                      }
                   //Get all categories from the database.
                   return try acronym.categories.query(on: req).all()
                     .flatMap(to: Response.self) { existingCategories in
                      //Create an array of category names from the categories in the database.
                      let existingStringArray =
                        existingCategories.map { $0.name }
                      
                      //Create a Set for the categories in the database and another for the categories supplied with the request.
                      let existingSet = Set<String>(existingStringArray)
                      let newSet = Set<String>(data.categories ?? [] )
                      
                      //Calculate the categories to add to the acronym and the categories to remove.
                      let categoriesToAdd = newSet.subtracting(existingSet)
                      let categoriesToRemove = existingSet.subtracting(newSet)
                      
                     //Create an array of category operation results.
                      var categoryResults: [Future<Void>] = []
                     
                     //Loop through all the categories to add and call Category.addCategory(_:to:on:) to set up the relationship.  Add each result to the results array.
                      for newCategory in categoriesToAdd {
                           categoryResults.append(
                            try Category.addCategory(newCategory, to: acronym, on: req))
                      }
                       //Loop through all the categories to remove from the acronym.
                      for categoryNameToRemove in categoriesToRemove {
                         //Get the Category object from the name of the category to remove.
                         let categoryToRemove = existingCategories.first {
                                $0.name == categoryNameToRemove
                         }
                        //If the Category object exists, use detach(_:on:) to remove the relationship and delete the pivot.
                         if let category = categoryToRemove {
                            categoryResults.append(
                                acronym.categories.detach(category, on: req))
                         }
                        }
                        //Flatten all the future category results.  Transform the result to redirect to the updated acronym's page.
                        return categoryResults
                            .flatten(on: req)
                            .transform(to: req.redirect(to: "/acronyms/\(id)"))
                        }
                    }
                }
        }
    

    
    
    
    
    
    
    
    
    //This route extracts the acronym from the request's parameter and calls delete(on:) on the acronym.  The route then transforms the result to redirect the page to the home screen.
    func deleteAcronymHandler(_ req: Request) throws -> Future<Response> {
        
        return try req.parameters.next(Acronym.self).delete(on: req)
            .transform(to: req.redirect(to: "/"))
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
    let categories: Future<[Category]>
}

struct UserContext: Encodable {
    let title: String
    //User object to which the page refers.
    let user: User
    let acronyms: [Acronym]
}

struct AllUsersContext: Encodable {
    let title: String
    let users: [User]
}

struct AllCategoriesContext: Encodable {
    
    //Define the page's title for the template.
    let title = "All Categories"
    //Define a future array of categories to display in the page.
    let categories: Future<[Category]>
}


struct CategoryContext: Encodable {
    //A title for the page; you'll set this as the category name.
    let title: String
    //The category for the page.
    //This isn't Future<Category> since you need the category's name to set the title.
    //This means you'll have to unwrap the future in your route handler.
    let category: Category
    //The category's acronyms, provided as a future.
    let acronyms: Future<[Acronym]>
    
}

struct CreateAcronymContext: Encodable {
    let title = "Create An Acronym"
    let users: Future<[User]>
}

struct EditAcronymContext: Encodable {
    // The title for the page: "Edit Acronym"
    let title = "Edit Acronym"
    // The acronym to edit.
    let acronym: Acronym
    // A future array of users to display in the form.
    let users: Future<[User]>
    // A flag to tell the template that the page is for editing an acronym.
    let editing = true
    
    let categories: Future<[Category]>
}

struct CreateAcronymData: Content {
    let userID: User.ID
    let short: String
    let long: String
    let categories: [String]?
}
