//
//  Backand.swift
//  Backand-iOS-SDK
//
//  Created by Haijian Huo on 3/28/17.
//  Copyright © 2017 Haijian Huo. All rights reserved.
//

import Foundation
import Alamofire
import SwiftKeychainWrapper

/// HTTP method definitions.
public enum Method: String {
    case POST, GET, PUT, DELETE
}

/// Request options
public enum BackandOption {
    case pageSize(Int)
    case pageNumber(Int)
    case sortArray([Sorter])
    case filterArray([Filter])
    case excludeArray([ExcludeOption])
    case deep(Bool)
    case relatedObjects(Bool)
    case returnObject(Bool)
    case search(String)
}

public enum ExcludeOption: String {
    case Metadata = "__metadata"
    case TotalRows = "totalRows"
}

/**
 Filter's allow you to apply constraints to the data that is returned.
 - parameters:
 - filedName: The name of the field you want to apply the filter to.
 - operatorType: The operation to be applied the field. E.g. Equal.
 - value: The value to compare with.
 */
public struct Filter {
    public enum OperatorType: String {
        case Equals = "equals"
        case NotEquals = "notEquals"
        case GreaterThan = "greaterThan"
        case GreaterThanOrEqualsTo = "greaterThanOrEqualsTo"
        case LessThan = "lessThan"
        case LessThanOrEqualsTo = "lessThanOrEqualsTo"
        case StartsWith = "startsWith"
        case EndsWith = "endsWith"
        case Contains = "contains"
        case NotContains = "notContains"
        case Empty = "empty"
        case NotEmpty = "notEmpty"
        case In = "in"
    }
    
    public let fieldName: String
    public let operatorType: OperatorType
    public let value: AnyObject
    
    public init(fieldName: String, operatorType: OperatorType, value: AnyObject) {
        self.fieldName = fieldName
        self.operatorType = operatorType
        self.value = value
    }
    
    
    func asObject() -> [String: AnyObject] {
        var object: [String: AnyObject] = [:]
        object["fieldName"] = fieldName as AnyObject?
        object["operator"] = operatorType.rawValue as AnyObject?
        object["value"] = value
        return object
    }
}

/**
 Sorter's allow you to apply sorting to the data that is returned.
 - parameters:
 - filedName: The name of the field you want to apply the sorter to.
 - orderType: Asc or Desc order.
 */
public struct Sorter {
    public enum OrderType: String {
        case Asc = "asc"
        case Desc = "desc"
    }
    
    public let fieldName: String
    public let orderType: OrderType
    
    public init(fieldName: String, orderType: OrderType) {
        self.fieldName = fieldName
        self.orderType = orderType
    }
    
    func asObject() -> [String: AnyObject] {
        var object: [String: AnyObject] = [:]
        object["fieldName"] = fieldName as AnyObject?
        object["order"] = orderType.rawValue as AnyObject?
        return object
    }
}

/**
 Action's can be used to create bulk operations.
 - parameters:
 - method: HTTP method. Possible values: POST, PUT & DELETE.
 - url: The URL for the object.
 - data: JSON hash.
 */
public struct Action {
    let method: Method
    let url: String
    let data: [String: AnyObject]?
    
    func asObject() -> [String: AnyObject] {
        var object: [String: AnyObject] = [:]
        object["method"] = method.rawValue as AnyObject?
        object["url"] = url as AnyObject?
        if let data = data {
            object["data"] = data as AnyObject?
        }
        return object
    }
}

/// Basic class to interact with Backand REST API.
open class Backand: NSObject {
    
    // MARK: Types
    
    public typealias CompletionHandlerType = (Result) -> Void
    
    /// Used to represent whether a request was successful or not.
    public enum Result {
        case success(AnyObject?)
        case failure(NSError)
    }
    
    public enum BackandAuth {
        case anonymous, user, signUp
    }
    
    fileprivate struct Constants {
        static let userTokenKey = "userTokenKey"
    }
    
    /// Manages all requests sent to Backand
    fileprivate enum Router: URLRequestConvertible {
        static var baseURLString = "https://api.backand.com"
        static var apiVersion = "1"
        static var appName: String?
        static var authMode: BackandAuth = .anonymous
        static var signUpToken: String?
        static var anonymousToken: String?
        static var userToken: String? {
            get {
                return KeychainWrapper.standard.string(forKey: Constants.userTokenKey)
            }
            set {
                if let token = newValue {
                    KeychainWrapper.standard.set(token, forKey: Constants.userTokenKey)
                } else {
                    KeychainWrapper.standard.removeObject(forKey: Constants.userTokenKey)
                }
            }
        }
        
        case createItem(name: String, query: String?, parameters: [String: AnyObject])
        case updateItem(name: String, id: String, query: String?, parameters: [String: AnyObject])
        case readItem(name: String, id: String, query: String?)
        case readItems(name: String, query: String?)
        case deleteItem(name: String, id: String)
        case runQuery(name: String, parameters: [String: AnyObject]?)
        case performActions(body: [[String: AnyObject]])
        case signUp(user: [String: AnyObject])
        case signIn(username: String, password: String)
        
        var method: Method {
            switch self {
            case .createItem, .performActions, .signUp, .signIn:
                return .POST
            case .readItem, .readItems, .runQuery:
                return .GET
            case .updateItem:
                return .PUT
            case .deleteItem:
                return .DELETE
            }
        }
        
        var path: String {
            switch self {
            case .createItem(let name, let query, _):
                return "/\(Router.apiVersion)/objects/\(name)"+(query ?? "")
            case .readItem(let name, let id, let query):
                return "/\(Router.apiVersion)/objects/\(name)/\(id)"+(query ?? "")
            case .readItems(let name, let query):
                return "/\(Router.apiVersion)/objects/\(name)"+(query ?? "")
            case .updateItem(let name, let id, let query, _):
                return "/\(Router.apiVersion)/objects/\(name)/\(id)"+(query ?? "")
            case .deleteItem(let name, let id):
                return "/\(Router.apiVersion)/objects/\(name)/\(id)"
            case .runQuery(let name, _):
                return "/\(Router.apiVersion)/query/data/\(name)"
            case .performActions:
                return "/\(Router.apiVersion)/bulk"
            case .signUp:
                return "/\(Router.apiVersion)/user/signup"
            case .signIn:
                return "/token"
            }
        }
        
        // MARK: URLRequestConvertible
        
        func asURLRequest() throws -> URLRequest {
            let URL = Foundation.URL(string: Router.baseURLString+path)!
            var request = URLRequest(url: URL)
            request.httpMethod = method.rawValue
            
            switch Router.authMode {
            case .anonymous:
                request.setValue(Router.anonymousToken, forHTTPHeaderField: "AnonymousToken")
            case .user:
                request.setValue("Bearer \(Router.userToken ?? "")", forHTTPHeaderField: "Authorization")
            case .signUp:
                request.setValue(Router.signUpToken, forHTTPHeaderField: "SignUpToken")
            }
            request.setValue(Router.appName, forHTTPHeaderField: "AppName")
            
            switch self {
            case .createItem(_, _, let parameters):
                return try JSONEncoding.default.encode(request, with: parameters)
            case .updateItem(_, _, _, let parameters):
                return try JSONEncoding.default.encode(request, with: parameters)
            case .runQuery(_, let parameters):
                return try JSONEncoding.default.encode(request, with: parameters)
            case .performActions(let body):
                request.httpBody = try! JSONSerialization.data(withJSONObject: body, options: JSONSerialization.WritingOptions())
                return request
            case .signUp(let user):
                return try JSONEncoding.default.encode(request, with: user)
            case .signIn(let username, let password):
                let params = ["username": username, "password": password, "grant_type": "password", "appName": Router.appName ?? ""]
                return try JSONEncoding.default.encode(request, with: params)
            default:
                return request
            }
        }
    }
    
    // MARK: Properties
    
    open static let sharedInstance = Backand()
    
    // MARK: Configuration methods
    
    /**
     Sets the Backand app name for your application.
     - parameter name:  The app name string.
     */
    open func setAppName(_ name: String) {
        Router.appName = name
    }
    
    /**
     Sets the value of the anonymous use token.
     - parameter token:  The application's anonymous token string.
     */
    open func setAnonymousToken(_ token: String) {
        Router.anonymousToken = token
    }
    
    /**
     Sets the value of the user registration token.
     - parameter token:   The application's sign up token string.
     */
    open func setSignUpToken(_ token: String) {
        Router.signUpToken = token
    }
    
    /**
     Sets the base API URL for this application. Defualt value is "https://api.backand.com".
     - parameter url:  The API URL string.
     */
    open func setApiUrl(_ url: String) {
        Router.baseURLString = url
    }
    
    /**
     Returns the base API URL for this application.
     - returns: A string representing the base API URL.
     */
    open func getApiUrl() -> String {
        return Router.baseURLString
    }
    
    /**
     Change authenication mode.
     - parameter mode: Authentication mode.
     */
    open func setAuthMode(_ mode: BackandAuth) {
        Router.authMode = mode
    }
    
    // MARK: Authentication
    
    /**
     Registers a user for the application.
     - parameters:
     - user: User dictionary.
     - signinAfterSignup: Performs a sign in after a user signs up. This configuration is irrelevant when signing up with a social provider, since the user is always signed in after sign-up.
     - handler: The code to be executed once the request has finished.
     */
    open func signUp(_ user: [String: AnyObject], signinAfterSignup: Bool = true, handler: @escaping CompletionHandlerType) {
        Router.authMode = .signUp
        Alamofire.request(Router.signUp(user: user)).validate().responseJSON { response in
            switch response.result {
            case .success:
                if signinAfterSignup {
                    if let JSON = response.result.value as? [String: Any] {
                        if let token = JSON["token"] as? String {
                            Router.userToken = token
                            Router.authMode = .user
                        }
                    }
                }
                handler(Result.success(response.result.value as AnyObject?))
            case .failure(let error):
                handler(Result.failure(error as NSError))
            }
        }
    }
    
    /**
     Signs the specified user into the application.
     - parameters:
     - username: The user's email.
     - password: The user's password.
     - handler: The code to be executed once the request has finished.
     */
    open func signIn(_ username: String, password: String, handler: @escaping CompletionHandlerType) {
        Alamofire.request(Router.signIn(username: username, password: password)).validate().responseJSON { response in
            switch response.result {
            case .success:
                if let JSON = response.result.value as? [String: Any] {
                    if let token = JSON["access_token"] as? String {
                        Router.userToken = token
                        Router.authMode = .user
                    }
                }
                handler(Result.success(response.result.value as AnyObject?))
            case .failure(let error):
                handler(Result.failure(error as NSError))
            }
        }
    }
    
    /// Signs the currently authenticated user out of the application.
    open func signOut() {
        Router.userToken = nil
        Router.authMode = .anonymous
    }
    
    /**
     Returns status of user sign in.
     - returns: True if user is signed in and false if not.
     */
    open func userSignedIn() -> Bool {
        return (Router.userToken != nil) ? true : false
    }
    
    // MARK: Query string
    
    /**
     Converts an array of BackandOption into a query string
     - parameter options: An array of BackandOption(s).
     - returns: A query string.
     */
    fileprivate func queryStringFromOptions(_ options: [BackandOption]) -> String {
        /**
         Converts an Array of Filter objects into a query string.
         - parameter filters: An array of Filter(s).
         - returns: A query string.
         */
        func filterStringFromFilters(_ filters: [Filter]) -> String? {
            var filterArray = [[String: AnyObject]]()
            for filter in filters {
                filterArray.append(filter.asObject())
            }
            var filterString: String?
            let jsonData = try! JSONSerialization.data(withJSONObject: filterArray, options: [])
            if let jsonString = NSString(data: jsonData, encoding: String.Encoding.ascii.rawValue) {
                if let encodedString = jsonString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) {
                    filterString = encodedString
                }
            }
            return filterString
        }
        
        /**
         Converts an Array of Sorter objects into a query string.
         - parameter filters: An array of Sorter(s).
         - returns: A query string.
         */
        func sorterStringFromSorters(_ sorters: [Sorter]) -> String? {
            var sorterArray = [[String: AnyObject]]()
            for sorter in sorters {
                sorterArray.append(sorter.asObject())
            }
            var sorterString: String?
            let jsonData = try! JSONSerialization.data(withJSONObject: sorterArray, options: [])
            if let jsonString = NSString(data: jsonData, encoding: String.Encoding.ascii.rawValue) {
                if let encodedString = jsonString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) {
                    sorterString = encodedString
                }
            }
            return sorterString
        }
        
        /**
         Converts an Array of ExcludeOption objects into a query string.
         - parameter options: An array of Filter(s).
         - returns: A query string.
         */
        func excludeStringFromExcludeOptions(_ options: [ExcludeOption]) -> String {
            var excludeString = ""
            for (index, exclude) in options.enumerated() {
                excludeString += exclude.rawValue
                if index != options.count-1 {
                    excludeString += ","
                }
            }
            return excludeString
        }
        
        var query = "?"
        for (index, option) in options.enumerated() {
            switch option {
            case .pageSize(let size):
                query += "pageSize=\(size)"
            case .pageNumber(let number):
                query += "pageNumber=\(number)"
            case .filterArray(let filters):
                query += "filter=\(filterStringFromFilters(filters) ?? "")"
            case .sortArray(let sorters):
                query += "sorter=\(sorterStringFromSorters(sorters) ?? "")"
            case .excludeArray(let excluded):
                query += "exclude=\(excludeStringFromExcludeOptions(excluded))"
            case .deep(let deep):
                query += "deep=\(deep)"
            case .relatedObjects(let related):
                query += "relatedObjects=\(related)"
            case .returnObject(let shouldReturn):
                query += "returnObject=\(shouldReturn)"
            case .search(let searchString):
                query += "search=\(searchString)"
            }
            if index != options.count-1 {
                query += "&"
            }
        }
        return query
    }
    
    // MARK: GET
    
    /**
     Returns a single item.
     - parameters:
     - id: The item identity (id).
     - name: The object name.
     - options: Request options.
     - handler: The code to be executed once the request has finished.
     */
    open func getItemWithId(_ id: String, name: String, options: [BackandOption]?, handler: @escaping CompletionHandlerType) {
        var query: String? = nil
        if let options = options {
            query = queryStringFromOptions(options)
        }
        Alamofire.request(Router.readItem(name: name, id: id, query: query)).validate().responseJSON { response in
            switch response.result {
            case .success:
                handler(Result.success(response.result.value as AnyObject?))
            case .failure(let error):
                handler(Result.failure(error as NSError))
            }
        }
    }
    
    /**
     Gets list of items with filter, sort and paging parameters.
     - parameters:
     - name: The object name.
     - options: Request options.
     - handler: The code to be executed once the request has finished.
     */
    open func getItemsWithName(_ name: String, options: [BackandOption]?, handler: @escaping CompletionHandlerType) {
        var query: String? = nil
        if let options = options {
            query = queryStringFromOptions(options)
        }
        Alamofire.request(Router.readItems(name: name, query: query)).validate().responseJSON { response in
            switch response.result {
            case .success:
                handler(Result.success(response.result.value as AnyObject?))
            case .failure(let error):
                handler(Result.failure(error as NSError))
            }
        }
    }
    
    /**
     Executes a predefined query. You can define queries in your Backand dashboard.
     - parameters:
     - object: The object that you want to create.
     - name: The name of the query.
     - parameters: Query parameters.
     - handler: The code to be executed once the request has finished.
     */
    open func runQueryWithName(_ name: String, parameters: [String: AnyObject]?, handler: @escaping CompletionHandlerType) {
        Alamofire.request(Router.runQuery(name: name, parameters: parameters)).validate().responseJSON { response in
            switch response.result {
            case .success:
                handler(Result.success(response.result.value as AnyObject?))
            case .failure(let error):
                handler(Result.failure(error as NSError))
            }
        }
    }
    
    // MARK: POST
    
    /**
     Creates a new item.
     - parameters:
     - object: The object that you want to create.
     - name: The object name.
     - options: Request options.
     - handler: The code to be executed once the request has finished.
     */
    open func createItem(_ item: [String: AnyObject], name: String, options: [BackandOption]?, handler: @escaping CompletionHandlerType) {
        var query: String? = nil
        if let options = options {
            query = queryStringFromOptions(options)
        }
        
        Alamofire.request(Router.createItem(name: name, query: query, parameters: item)).validate().responseJSON { response in
            switch response.result {
            case .success:
                handler(Result.success(response.result.value as AnyObject?))
            case .failure(let error):
                handler(Result.failure(error as NSError))
            }
        }
    }
    
    /**
     Executes an array of Action(s).
     - parameters:
     - actions: An array of Action(s).
     - handler: The code to be executed once the request has finished.
     */
    open func performActions(_ actions: [Action], handler: @escaping CompletionHandlerType) {
        var actionArray = [[String: AnyObject]]()
        for action in actions {
            actionArray.append(action.asObject())
        }
        Alamofire.request(Router.performActions(body: actionArray)).validate().responseJSON { response in
            switch response.result {
            case .success:
                handler(Result.success(response.result.value as AnyObject?))
            case .failure(let error):
                handler(Result.failure(error as NSError))
            }
        }
    }
    
    // MARK: PUT
    
    /**
     Updates a single item.
     - parameters:
     - id: The item identity (id).
     - object: The object that you want to update.
     - name: The object name.
     - options: Request options.
     - handler: The code to be executed once the request has finished.
     */
    open func updateItemWithId(_ id: String, item: [String: AnyObject], name: String, options: [BackandOption]?, handler: @escaping CompletionHandlerType) {
        var query: String? = nil
        if let options = options {
            query = queryStringFromOptions(options)
        }
        Alamofire.request(Router.updateItem(name: name, id: id, query: query, parameters: item)).validate().responseJSON { response in
            switch response.result {
            case .success:
                handler(Result.success(response.result.value as AnyObject?))
            case .failure(let error):
                handler(Result.failure(error as NSError))
            }
        }
    }
    
    // MARK: DELETE
    
    /**
     Deletes an item.
     - parameters:
     - id: The item identity (id).
     - name: The object name.
     - options: Request options.
     - handler: The code to be executed once the request has finished.
     */
    open func deleteItemWithId(_ id: String, name: String, handler: @escaping CompletionHandlerType) {
        Alamofire.request(Router.deleteItem(name: name, id: id)).validate().responseJSON { response in
            switch response.result {
            case .success:
                handler(Result.success(response.result.value as AnyObject?))
            case .failure(let error):
                handler(Result.failure(error as NSError))
            }
        }
    }
    
}
