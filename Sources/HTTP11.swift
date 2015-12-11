//
//  HTTP11.swift
//  Swerver
//
//  Created by Julius Parishy on 12/5/15.
//  Copyright © 2015 Julius Parishy. All rights reserved.
//

import Foundation

class HTTP11 : HTTPVersion {
    let dataString: String?
    
    required init(rawRequest: NSData) {
#if os(Linux)
	dataString = NSString(bytes: rawRequest.bytes, length: rawRequest.length, encoding: NSUTF8StringEncoding)?.bridge()
#else
        dataString = NSString(bytes: rawRequest.bytes, length: rawRequest.length, encoding: NSUTF8StringEncoding) as? String
#endif
        print(dataString)
    }
    
    func request() -> Request? {
        if let lines = dataString?.bridge().componentsSeparatedByString("\n") {
            if let first = lines.first {
                let parts = first.bridge().componentsSeparatedByString(" ")
                if parts.count == 3 {
                    let rest = Array(lines.dropFirst())
                    let (headers, requestBody) = parseHeadersAndBodyFromRestOfLines(rest)
                    return Request(method: parts[0], path: parts[1], headers: headers, requestBody: requestBody)
                }
            }
        }
        
        return nil
    }
    
    private func parseHeadersAndBodyFromRestOfLines(lines: [String]) -> (Headers, NSData?) {
        var headers: [String:String] = [:]
        var data: NSMutableData? = NSMutableData()
        
        var stillParsingHeaders = true
        for line in lines {
            if line.bridge().stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()).bridge().lengthOfBytesUsingEncoding(NSUTF8StringEncoding) == 0 {
                stillParsingHeaders = false
                continue
            }
            
            if stillParsingHeaders {
                let components = line.bridge().componentsSeparatedByString(":").map {
                    str in
                    str.bridge().stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                }
                if components.count == 2 {
                    headers[components[0]] = components[1]
                }
            } else {
                let trimmed = line.bridge().stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()).bridge().stringByAppendingString("\n")
                let chunk = NSData(bytes: unsafeBitCast(trimmed.bridge().swerver_cStringUsingEncoding(NSUTF8StringEncoding), UnsafePointer<Void>.self), length: trimmed.bridge().lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
                    
                data?.appendData(chunk)
            }
        }
        
        if let d = data where d.length == 0 {
            data = nil
        }
        
        return (headers, data)
    }
    
    func response(statusCode: StatusCode, headers: Headers, data: [UInt8]?) -> NSData {
    
        var output = ""
        output += "HTTP/1.1 \(statusCodeStringFromStatusCode(statusCode))\n"
        output += "Server: \(SwerverName)/\(SwerverVersion)\n"
        
        var allHeaders = headers
        for (key, value) in statusCode.additionalHeaders {
            allHeaders[key] = value
        }
        
        if allHeaders["Cache-Control"] == nil {
            allHeaders["Cache-Control"] = "no-cache"
        }
        
        let addHeaders = {
            for (name, value) in allHeaders {
                output += "\(name): \(value)\n"
            }
        }
        
        if let d = data, str = NSString(CString: UnsafePointer(d), encoding: NSUTF8StringEncoding) {
            output += "Content-Length: \(str.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))\n"
            addHeaders()
            output += "\r\n"
            output += (str as String)
        } else {
            output += "Content-Length: 0\n"
            addHeaders()
            output += "\r\n"
        }
        
        let cString = output.swerver_cStringUsingEncoding(NSUTF8StringEncoding)
        let bytes = UnsafePointer<Int8>(cString)
        return NSData(bytes: bytes, length: output.bridge().lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
    }
    
    private func statusCodeStringFromStatusCode(statusCode: StatusCode) -> String {
        let integerCode = statusCode.integerCode
        switch integerCode {
        case 200:
            return "200 OK"
        case 301:
            return "301 Moved Permanently"
        case 404:
            return "404 Not Found"
        case (500...599):
            return "\(statusCode) Internal Service Error"
        default:
            return "400 Invalid Request"
        }
    }
}
