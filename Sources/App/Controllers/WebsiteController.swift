import Vapor
import Authentication
//import Leaf

// Declare a new WebsiteController type that conforms to RouteCollection.
// RouteCollection: Groups collections of routes together for adding to a router.
struct WebsiteController: RouteCollection {
    
    // Implement boot(router:) as required by RouteCollection
    func boot(router: Router) throws {
        
        //This creates a route group that runs AuthenticationSessionsMiddleware before the route handlers.
        //This middleware reads the cookie from the request and looks up the session ID in the application's session list.
        //If the session contains a user, AuthenticationSessionMiddleware adds it to the AuthenticationCache, making the user available later in the process.
        let authSessionRoutes = router.grouped(User.authSessionsMiddleware())
        
        
        //Register all the public routes:
        authSessionRoutes.get(use: indexHandler)
        authSessionRoutes.get("acronyms", Acronym.parameter, use: acronymHandler)
        authSessionRoutes.get("users", User.parameter, use: userHandler)
        authSessionRoutes.get("users", use: allUsersHandler)
        authSessionRoutes.get("categories", use: allCategoriesHandler)
        authSessionRoutes.get("categories", Category.parameter, use: categoryHandler)
        authSessionRoutes.get("login", use: loginHandler)
        authSessionRoutes.post(LoginPostData.self, at: "login", use: loginPostHandler)
        authSessionRoutes.post("logout", use: logoutHandler)
        
        //Connect a GET request for /register to registerHandler
        authSessionRoutes.get("register", use: registerHandler)
        
        //Connect a POST request for /register to registerPostHandler(_:data:).
        //Decode the request's body to RegisterData.
        authSessionRoutes.post(RegisterData.self, at: "register", use: registerPostHandler)
        
        
        //This creates a new route group, extending from authSessionRoutes, that includes RedirectMiddleware.
        //The application runs a request through RedirectMiddleware before it reaches the route handler, but after AuthenticationSessionsMiddleware.
        //This allows RedirectMiddleware to check for an authenticated user.
        //RedirectMiddleware requires you to specify the path for redirecting unauthenticated users and the Authenticatable type to check for. In this case, that's your User model.
        let protectRoutes = authSessionRoutes.grouped(RedirectMiddleware<User>(path: "/login"))
        
        
        //Routes that require protection:
        protectRoutes.get("acronyms", "create", use: createAcronymHandler)
        protectRoutes.post(CreateAcronymData.self, at: "acronyms", "create", use: createAcronymPostHandler)
        protectRoutes.get("acronyms", Acronym.parameter, "edit", use: editAcronymHandler)
        protectRoutes.post("acronyms", Acronym.parameter, "edit", use: editAcronymPostHandler)
        protectRoutes.post("acronyms", Acronym.parameter, "delete", use: deleteAcronymHandler)
        
        
        //        //Register indexHandler(_:) to process GET requests to the router's root path,
        //        //      i.e a request to /.
        //        router.get(use: indexHandler)
        //
        //        //Register acronynHandler route for /acronyms/<ACRONYM ID> similar to the API.
        //        router.get("acronyms", Acronym.parameter, use: acronymHandler)
        //
        //        //Register userHandler for /users/<USER ID>
        //        router.get("users", User.parameter, use: userHandler)
        //
        //        //Register allUsersHandler for /users/
        //        router.get("users", use: allUsersHandler)
        //
        //        //Register a route at /categories that accepts GET requests and calls allCategoriesHandler(_:).
        //        router.get("categories", use: allCategoriesHandler)
        //        //Register a route at /categories/<CATEGORY ID> that accepts GET requests and calls categoryHandler(_:)
        //        router.get("categories", Category.parameter, use: categoryHandler)
        //
        //        //Register a route at /acronyms/create that accepts GET requests and calls createAcronymHandler(_:)
        //        router.get("acronyms", "create", use: createAcronymHandler)
        //        //Register a route at /acronyms/create that accepts POST requests and calls
        //        //  createAcronymPostHandler(_:acronym:).  This also decodes the request's body to an Acronym.
        //        //router.post(Acronym.self, at: "acronyms", "create", use: createAcronymPostHandler)
        //        router.post(CreateAcronymData.self, at: "acronyms", "create", use: createAcronymPostHandler)
        //
        //        //Register a route a /acronyms/<ACRONYM_ID>/edit to accept GET requests that calls editAcronymHandler(_:).
        //        router.get("acronyms", Acronym.parameter, "edit", use: editAcronymHandler)
        //
        //        //Register a route to handle POST requests to the same URL that calls editAcronymPostHandler(_:)
        //        router.post("acronyms", Acronym.parameter, "edit", use: editAcronymPostHandler)
        //
        //        //Register the delete route.
        //        //Registers a route at /acronyms/<ACRONYM ID>/delete to accept POST requests and call deleteAcronymHandler(_:).
        //        router.post("acronyms", Acronym.parameter, "delete", use: deleteAcronymHandler)
        //
        //        //Route GET requests for /login to loginHandler(_:)
        //        router.get("login", use: loginHandler)
        //
        //        //Route POST requests for /login to loginPostHandler(_:userData:),
        //        //      decoding the request body into LoginPostData.
        //        router.post(LoginPostData.self, at: "login", use: loginPostHandler)
        //
        
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
                let acronymsData = acronyms.isEmpty ? nil : acronyms
                //let context = IndexContext(title: "Homepage",
                //                           acronyms: acronymData)
                
                //Check if the request contains an authenticated user.
                let userLoggedIn = try req.isAuthenticated(User.self)
                //Pass the result to the new flag in IndexContext.
                //let context = IndexContext(title: "Homepage", acronyms: acronymsData, userLoggedIn: userLoggedIn)
                
                let showCookieMessage = req.http.cookies["cookies-accepted"] == nil
                
                //
                let context = IndexContext(title: "Homepage", acronyms: acronymsData, userLoggedIn: userLoggedIn, showCookieMessage: showCookieMessage)
                
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
        //let context = CreateAcronymContext(users: User.query(on: req).all())
        //let context = CreateAcronymContext()
        
        //Create a token using 16 bytes of randomly generated data, base64 encoded.
        let token = try CryptoRandom().generateData(count: 16).base64EncodedString()
        
        //Initialize CreateAcronymContext with the created token.
        let context = CreateAcronymContext(csrfToken: token)
        
        //Save the token into the request's session under the CSRF_TOKEN key.
        try req.session()["CSRF_TOKEN"] = token
        
        print("This is the token in createAcronymHandler: \(token)")
        
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
        
        //Get the expected token from the request's session.
        // This is the token you saved in createAcronymHandler(_:)
        let expectedToken = try req.session()["CSRF_TOKEN"]
        
        //Clear the CSRF token now that you've used it.
        //  You generate a new token with each form.
        try req.session()["CSRF_TOKEN"] = nil
        
        print("data.csrfToken: \(data.csrfToken)")
        
        //Ensure the provided token matches the expected token.
        //  otherwise, throw a 400 bad request error.
        guard expectedToken == data.csrfToken else {
            throw Abort(.badRequest)
        }
        
        print("Expected token: \(expectedToken)")
        
        //Create an Acronym object to save as it's no longer passed into the route.
        //let acronym = Acronym(short: data.short, long: data.long, userID: data.userID)
        
        //Get the user from the request using requireAuthenticated(User.self)
        let user = try req.requireAuthenticated(User.self)
        let acronym = try Acronym(short: data.short, long: data.long, userID: user.requireID())
        
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
                
                //let users = User.query(on: req).all()
                let categories = try acronym.categories.query(on: req).all()
                //let context = EditAcronymContext(acronym: acronym, users: users, categories: categories)
                
                let context = EditAcronymContext(acronym: acronym, categories: categories)
                
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
                //Get the authenticated user from the request.
                let user = try req.requireAuthenticated(User.self)
                acronym.short = data.short
                acronym.long = data.long
                acronym.userID = try user.requireID()
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
    
    
    // Define a route handler for the login page that returns a future View.
    func loginHandler(_ req: Request) throws -> Future<View> {
        let context: LoginContext
        // If the request contains the error parameter, create a context with loginError set to true.
        if req.query[Bool.self, at: "error"] != nil {
            context = LoginContext(loginError: true)
        } else {
            context = LoginContext()
        }
        // Render the login.leaf template, passing in the context.
        return try req.view().render("login", context)
    }
    
    
    //Define the route handler that decodes LoginPostData from the request and returns Future<Response>
    func loginPostHandler(_ req: Request, userData: LoginPostData) throws -> Future<Response> {
        //Call authenticate(username:password:using:on).
        //This checks the username and password against the database and verifies the BCrypt hash.
        //This function returns a nil user in a future if there's an issue authenticating the user.
        return User.authenticate(username: userData.username, password: userData.password, using: BCryptDigest(), on: req).map(to: Response.self) { user in
            
            //Verify authenticate(username:password:using:on:) returned an authenticated user; otherwise, redirect back to the login page to show an error.
            guard let user = user else {
                return req.redirect(to: "/login?error")
            }
            
            //Authenticate the request's session.
            //This saves the authenticated User into the request's session so Vapor can retrieve it in later requests.  This is how Vapor persists authentication when a user logs in.
            try req.authenticateSession(user)
            
            //Redirect to the homepage after the login succeeds.
            return req.redirect(to: "/")
            
        }
    }
    
    //Define a route handler that simply returns Response.
    // There's no asynchronous work in this function so it doesn't need to return a future.
    func logoutHandler(_ req: Request) throws -> Response {
        //Call unauthenticateSession(_:) on the request.
        // This deletes the user from the session so it can't be used to authenticate future requests.
        try req.unauthenticateSession(User.self)
        // Return a redirect to the index page.
        return req.redirect(to: "/")
    }
    
    //Route handler for the registration page.
    func registerHandler(_ req: Request) throws -> Future<View> {
        //let context = RegisterContext()
        
        //This check the request's query.
        //If message exist's - i.e. the URL is /register?message=some-string
        // the route handler includes it in the context Leaf uses to render the page.
        let context: RegisterContext
        if let message = req.query[String.self, at: "message"] {
            context = RegisterContext(message: message)
        } else {
            context = RegisterContext()
        }
        
        return try req.view().render("register", context)
    }
    
    // Define a route handler that accepts a request and the decoded RegisterData.
    func registerPostHandler(_ req: Request, data: RegisterData) throws -> Future<Response> {
        
        //The following calls validate() on the decoded RegisterData.
        // checking each validator you added previously.
        // validate() can throw ValidationError.
        // In an API, you can let this error propogate back to the user but, on a website,
        //  that doesn't make for a good user experience.  In this case, you redirect the user back to the
        //      register page.
        do {
            try data.validate()
        } catch (let error) {
            
            /*
            When validation fails, the route handler extracts the message from the ValidationError,
             escapes it properly for inclusion in a URL, and adds it to the redirect URL.
             Then, it redirects the user back to the registration page.
            */
            
            let redirect: String
        
            if let error = error as? ValidationError,
                let message = error.reason.addingPercentEncoding(
                    withAllowedCharacters: .urlQueryAllowed) {
                redirect = "/register?message=\(message)"
            } else {
                redirect = "/register?message=Unknown+error"
            }
            return req.future(req.redirect(to: redirect))
        }
        
        
        
        
        //Hash the password submitted to the form.
        let password = try BCrypt.hash(data.password)
        
        //Create a new User, using the data from the form and the hashed password.
        let user = User(name: data.name, username: data.username, password: password)
        
        //Save the new user and unwrap the returned future.
        return user.save(on: req).map(to: Response.self) { user in
            //Authenticate the session for the new user.
            // This automatically logs users in when they register, thereby providing a nice user experience when signing up with the site.
            try req.authenticateSession(user)
            //Return a redirect back to the home page.
            return req.redirect(to: "/")
            
        }
    }
}

//IndexContent is the data for your view, similar to a view model in the MVVM design pattern.
struct IndexContext: Encodable {
    //Properties to be displayed on the website.
    let title: String
    //Optional - it can be nil as there may be no acronyms in the database.
    let acronyms: [Acronym]?
    let userLoggedIn: Bool
    
    //This flag indicate to the template whether is should display the cookie consent message.
    let showCookieMessage: Bool
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
    //let users: Future<[User]>
    
    //This is the CRSF token you'll pass into the template.
    let csrfToken: String
    
}

struct EditAcronymContext: Encodable {
    // The title for the page: "Edit Acronym"
    let title = "Edit Acronym"
    // The acronym to edit.
    let acronym: Acronym
    // A future array of users to display in the form.
    //let users: Future<[User]>
    // A flag to tell the template that the page is for editing an acronym.
    let editing = true
    
    let categories: Future<[Category]>
    
}

struct CreateAcronymData: Content {
    //This is no longer required since you can get it from the authenticated user.
    //let userID: User.ID
    let short: String
    let long: String
    let categories: [String]?
    //This is the CSRF Token that the form sends using the hidden input.
    let csrfToken: String
}


//Create a context for the login page.
//This provides the title of the page and a flag to indicate a login error.
struct LoginContext: Encodable {
    let title = "Log In"
    let loginError: Bool
    
    init(loginError: Bool = false) {
        self.loginError = loginError
    }
}


//A Content type that defines the data you expect when you receive the login POST request.
struct LoginPostData: Content {
    let username: String
    let password: String
}


//Context for the registration page.
struct RegisterContext: Encodable {
    let title = "Register"
    
    //This is the message to display on the registration page.
    // Remember that Leaf handles nil gracefully, allowing you to use the default value in the normal case.
    let message: String?
    init(message: String? = nil) {
        self.message = message
    }
}

//This Content type matches the expected data received from the registration POST request.
//This variables match the names of the inputs in register.leaf.
struct RegisterData: Content {
    let name: String
    let username: String
    let password: String
    let confirmPassword: String
}


//Extend RegisterData to make it conform to Validatable and Reflectable.
//Validatable allows you to validate types with Vapor.
//Reflectable provides a way to discover the internal components of a type.
extension RegisterData: Validatable, Reflectable {
    // Implement validations() as required by Validatable.
    static func validations() throws -> Validations<RegisterData> {
        
        // Create a Validations type to contain the various validators.
        var validations = Validations(RegisterData.self)
        // Add a validator to ensure RegisterData's name contains only ASCII characters.
        // Note: Be careful when adding restrictions on names like this.
        //  Some countries, such as China, don't have names with ASCII characters.
        try validations.add(\.name, .ascii)
        // Add a validator to ensure the username contains only alphanumeric characters and is at least 3 characters long.    .count(_:) takes a Swift Range, allowing you to create both open-ended and closed ranges, if required.
        try validations.add(\.username,
                            .alphanumeric && .count(3...))
        // Add a validator to ensure the password is at least 8 characters long.
        try validations.add(\.password, .count(8...))
        
        
        //Use Validation's add(_:_) to add a custom validation for RegisterData.
        //  This takes a readable description as the first parameter.
        //  The second parameter is a closure that should throw if validation fails.
        validations.add("passwords match") { model in
            // Verify that password and confirmPassword match.
            guard model.password == model.confirmPassword else {
                // If they don't, throw BasicValidationError.
                throw BasicValidationError("passwords don't match")
            }
        }
        
        
        
        
        
        
        // Return the validations for Vapor to test.
        return validations
    }
}
