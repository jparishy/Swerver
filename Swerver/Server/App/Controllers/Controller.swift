//
//  Controller.swift
//  Swerver
//
//  Created by Julius Parishy on 12/11/15.
//  Copyright © 2015 Julius Parishy. All rights reserved.
//

import Foundation

class ControllerResponse : Response {
    let session: Session
    
    init(_ response: Response) {
        session = Session()
        super.init(response.statusCode, headers: response.headers, responseData: response.responseData)
    }
    
    init(_ statusCode: StatusCode, headers: Headers = [:], responseData: ResponseData? = nil, session: Session = Session()) {
        self.session = session
        super.init(statusCode, headers: headers, responseData: responseData)
    }
}

typealias ControllerRequestHandler = (request: Request, parameters: Parameters, session: Session, transaction: Transaction) throws -> ControllerResponse

class Controller : RouteProvider {

    internal weak var resource: Resource! = nil
    internal weak var application: Application! = nil
    
    required init() {
    }
    
    init(application app: Application) {
        application = app
    }
    
    func apply(request: Request) throws /* UserError, InternalServerError */ -> Response {
        do {
            if let subroute = resource?.subrouteForRequest(request) {
                
                let db = try connect()
                
                var allParameters = Parameters()
                
                for (k,v) in subroute.parameters() {
                    allParameters[k] = v
                }
                
                if let requestParameters = try parse(request) as? NSDictionary {
                    for (k,v) in requestParameters {
                        if let k = k as? String {
                            allParameters[k] = v
                        }
                    }
                }
                
                do {
                    var session: Session
                    if let cookiesString = request.headers["Cookie"] {
                        let cookies: [Cookie] = Cookie.parse(cookiesString)
                        let sessionCookie = cookies.filter { c in c.name == Session.CookieName }.first
                        if let sessionCookie = sessionCookie {
                            
                            let bytes = sessionCookie.value.bridge().swerver_cStringUsingEncoding(NSUTF8StringEncoding)
                            let data = NSData(bytes: bytes, length: bytes.count)
                            if let sessionFromJSON = Session(JSONData: data) {
                                session = sessionFromJSON
                            } else {
                                session = Session()
                            }
                        } else {
                            session = Session()
                        }
                    } else {
                        session = Session()
                    }
                    
                    let response: ControllerResponse = try db.transaction {
                        t in
                        
                        let response: ControllerResponse
                        switch subroute.action {
                        case .Index:
                            response = try self.index(request, parameters: allParameters, session: session, transaction: t)
                            break
                        case .Create:
                            response = try self.create(request, parameters: allParameters, session: session, transaction: t)
                            break
                        case .Update:
                            response = try self.update(request, parameters: allParameters, session: session, transaction: t)
                            break
                        case .Delete:
                            response = try self.delete(request, parameters: allParameters, session: session, transaction: t)
                            break
                        case .NamespaceIdentity:
                            response = self.builtin(.Ok)
                            break
                        case .Custom(_, let function):
                            response = try function(request: request, parameters: allParameters, session: session, transaction: t)
                            break
                        }
                        
                        t.commit()
                        
                        return response
                    }
                    
                    let statusCode = response.statusCode
                    var headers = response.headers
                    let responseData = response.responseData
                    
                    session.merge(otherSession: response.session)
                    
                    var sessionCookie: String? = nil
                    do {
                        let data = try NSJSONSerialization.swerver_dataWithJSONObject(session.dictionary, options: NSJSONWritingOptions(rawValue: 0))
                        let str = NSString(bytes: data.bytes, length: data.length, encoding: NSUTF8StringEncoding)
                        sessionCookie = str?.bridge()
                    } catch {
                        print("*** [ERROR]: Failed to write session to cookie.")
                    }
                    
                    if let sessionCookie = sessionCookie {
                        headers["Set-Cookie"] = "\(Session.CookieName)=\(sessionCookie); Path=/; Expires=Wed, 09 Jun 2021 10:18:14 GMT;HttpOnly"
                    }
                    
                    return Response(statusCode, headers: headers, responseData: responseData)
                    
                } catch {
                    return builtin(.InternalServerError)
                }
            } else {
                throw UserError.Unimplemented
            }
        } catch JSONError.UnexpectedToken(let message, _) {
            print("*** [ERROR]: \(message)")
            return builtin(.InternalServerError)
        } catch JSONError.InvalidInput {
            print("*** [ERROR]: Invalid JSON Input")
            return builtin(.InternalServerError)
        } catch DatabaseError.TransactionFailure(_, let message) {
            print("*** [ERROR]: \(message)")
            return builtin(.InternalServerError)
        } catch DatabaseError.OpenFailure(_, let message) {
            print("*** [ERROR]: \(message)")
            return builtin(.InternalServerError)
        } catch {
            print("*** [ERROR] Unknown Internal Service Error")
            return builtin(.InternalServerError)
        }
    }
    
    func index(request: Request, parameters: Parameters, session inSession: Session, transaction t: Transaction) throws /* UserError, InternalServerError */ -> ControllerResponse {
        throw UserError.Unimplemented
    }

    func create(request: Request, parameters: Parameters, session inSession: Session, transaction t: Transaction) throws /* UserError, InternalServerError */ -> ControllerResponse {
        throw UserError.Unimplemented
    }
    
    func update(request: Request, parameters: Parameters, session inSession: Session, transaction t: Transaction) throws /* UserError, InternalServerError */ -> ControllerResponse {
        throw UserError.Unimplemented
    }

    func delete(request: Request, parameters: Parameters, session inSession: Session, transaction t: Transaction) throws /* UserError, InternalServerError */ -> ControllerResponse {
        throw UserError.Unimplemented
    }
    
    func parse(request: Request) throws -> AnyObject? {
        if let body = request.requestBody {
            do {
                if let contentType: NSString = request.headers["Content-Type"]?.bridge() {
                    if contentType.rangeOfString("application/json").location != NSNotFound {
                        let JSON = try NSJSONSerialization.swerver_JSONObjectWithData(body, options: NSJSONReadingOptions(rawValue: 0))
                        return JSON
                    } else if contentType.rangeOfString("x-www-form-urlencoded").location != NSNotFound {
                        if let string = NSString(bytes: body.bytes, length: body.length, encoding: NSUTF8StringEncoding)?.swerver_stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) {
                            return parametersFromURLEncodedString(string)
                         } else {
                            return nil
                         }
                    } else {
                        return nil
                    }
                } else {
                    return nil
                }
            } catch {
                return nil
            }
        } else {
            return nil
        }
    }
    
    private func parametersFromURLEncodedString(str: String) -> Parameters {
        let parts = str.swerver_componentsSeparatedByString("&")
        
        var parameters = Parameters()
        
        for part in parts {
            let kvParts = part.swerver_componentsSeparatedByString("=")
            if kvParts.count == 2 {
                let k = kvParts[0]
                let v = kvParts[1]
                
                parameters[k] = v
            }
        }
        
        return parameters
    }
    
    func redirect(to to: String, headers: Headers = [:], session: Session = Session()) throws -> ControllerResponse {
        return ControllerResponse(.MovedPermanently(to: to), headers: headers, session: session)
    }
    
    func builtin(statusCode: StatusCode) -> ControllerResponse {
        let response = BuiltInResponse(statusCode, publicDirectory: self.application.publicDirectory)
        return ControllerResponse(response.statusCode, headers: response.headers, responseData: response.responseData)
    }
    
    func view(view: View, statusCode: StatusCode = .Ok, headers: Headers = [:]) -> ControllerResponse {
        let response = View.response(view, statusCode: statusCode, headers: headers)
        return ControllerResponse(response.statusCode, headers: response.headers, responseData: response.responseData)
    }
    
    func respond(request: Request, _ allowedContentTypes: [ContentType] = [], work: (responseContentType: ContentType) throws -> Response?) throws -> ControllerResponse {
        return ControllerResponse(try Respond(request, allowedContentTypes, work: work))
    }
    
    
    func connect() throws -> Database {
        return try Database(databaseName: "notes", username: "jp", password: "password")
    }
}
