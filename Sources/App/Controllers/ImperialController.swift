import Vapor
import Imperial
import Authentication

struct ImperialController: RouteCollection {
    
    func boot(router: Router) throws {
        //
        guard let callbackURL = Environment.get("GOOGLE_CALLBACK_URL") else {
            fatalError("Callback URL not set")
        }
        
        
        //Get the callback URL from an environment variable - this is the URL you set up in the Google console.
        //Register Imperial's Google OAuth router with your app's router.
        //Tell Imperial to use the Google handler
        //Set up the /login-google route as the route that triggers the OAuth flow.
        //     This is the route the application uses to allow users to log in via Google
        //Provide the callback URL to Imperial
        //Request the profile and email scopes from Google - the application needs these to create a user.
        //Set the completion handler to processGoogleLogin(request: token:) the method you created above.
        try router.oAuth(from: Google.self, authenticate: "login-google", callback: callbackURL, scope: ["profile", "email"], completion: processGoogleLogin)
        
        
    }
    
    // This defines a method to handle the Google login.
    // The handler simply redirects the user to the home page - the same way that the regular login works.
    // Imperial uses this method as the final callback once it has handled the Google redirect.
    // Notice the user of request.future(_:) to create a future from request.redirect(to:),
    //      since the function that Imperial uses requires a future.
    func processGoogleLogin(request: Request, token: String) throws -> Future<ResponseEncodable> {
        
        
        // Get the user information from Google.
        return try Google
            .getUser(on: request)
            .flatMap(to: ResponseEncodable.self) { userInfo in
                // See if the user exists in the database by looking up the email as the username.
                return User
                    .query(on: request)
                    .filter(\.username == userInfo.email)
                    .first()
                    .flatMap(to: ResponseEncodable.self) { foundUser in
                        
                        guard let existingUser = foundUser else  {
                            //If the user doesn't exist, create a new User using the name and email from the user information from Google.  Set the password to blank, since you don't need it.
                            let user = User(name: userInfo.name, username: userInfo.email, password: "")
                            //Save the user and unwrap the returned future.
                            return user
                                .save(on: request)
                                .map(to: ResponseEncodable.self) { user in
                                    //Call request.authenticateSession(_:) to save the created user in the session so the website allows access.  Redirect back to the homepage.
                                    try request.authenticateSession(user)
                                    return request.redirect(to: "/")
                                    
                            }
                        }
                        //If the user already exists, authenticate the user in the session and redirect to the homepage.
                        try request.authenticateSession(existingUser)
                        return request.future(request.redirect(to: "/"))
                }
        }
        
        
        
        
        
        
    }
}

//New type to decode the data from Google's API:
struct GoogleUserInfo: Content {
    let email: String
    let name: String
}


extension Google {
    
    // Add a new function to Imperial's Google service that gets a user's details from the Google API.
    static func getUser(on request: Request) throws -> Future<GoogleUserInfo> {
        // Set the headers for the request by adding the OAuth token to the authorization header.
        var headers = HTTPHeaders()
        headers.bearerAuthorization =
            try BearerAuthorization(token: request.accessToken())
        // Set the URL for the request - this is Google's API to get the user's information.
        let googleAPIURL = "https://www.googleapis.com/oauth2/v1/userinfo?alt=json"
        
        // Use request.client() to create a client to send a request.
        //get() sends an HTTP GET request to the URL provided.  Unwrap the returned future response.
        return try request
            .client()
            .get(googleAPIURL, headers: headers)
            .map(to: GoogleUserInfo.self) { response in
                // Ensure the response status is 200 OK
                guard response.http.status == .ok else {
                    // Otherwise return to the login page if the response was 401 Unauthorized or return an error.
                    if response.http.status == .unauthorized {
                        throw Abort.redirect(to: "/login-google")
                    } else {
                        throw Abort(.internalServerError)
                    }
                }
                // Decode the data from the response to GoogleUserInfo and return the result.
                return try response.content.syncDecode(GoogleUserInfo.self)
                    
            }
    }
}
