

//Define a function, cookiesConfirmed(), that the browser calls when the user click the OK link in the cookie message.

function cookiesConfirmed() {
        //Hide the cookie message.
        $('#cookie-footer').hide();
    
    // Create a data that's one year in the future.  Then, create the expires string required for the cookie.
    // By default, cookies are valid for the browser session - when the user closes the browser window or tab, the browser deletes the cookie.  Adding the date ensures the browser persists the cookie for a year.
    var d = new Date();
    d.setTime(d.getTime() + (365*24*60*1000));
    var expires = "expires=" + d.toUTCString();
    
    //Add a cookie called cookies-accepted to the page using JavaScript.
    // You'll check to see if this cookie exists when working out whether to show the cookie consent message.
    document.cookie = "cookies-accepted=true;" + expires;
}
