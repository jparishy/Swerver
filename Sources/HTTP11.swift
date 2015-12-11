//
//  HTTP11.swift
//  Swerver
//
//  Created by Julius Parishy on 12/5/15.
//  Copyright © 2015 Julius Parishy. All rights reserved.
//

import Foundation
import Glibc

class HTTP11 : HTTPVersion {
    let dataString: String?
    
    required init(rawRequest: NSData) {
#if os(Linux)
	if let bytes = NSString(bytes: rawRequest.bytes, length: rawRequest.length, encoding: NSUTF8StringEncoding)?.swerver_cStringUsingEncoding(NSUTF8StringEncoding) {
		dataString = String(bytes.map { b in Character(UnicodeScalar(b)) })
	} else {
		dataString = nil
	}
#else
        dataString = NSString(bytes: rawRequest.bytes, length: rawRequest.length, encoding: NSUTF8StringEncoding) as? String
#endif
        print("Data Str: \(dataString)")
    }
    
    func request() -> Request? {
        if let lines = dataString?.bridge().swerver_componentsSeparatedByString("\n") {
            if let first = lines.first {
                let parts = first.bridge().swerver_componentsSeparatedByString(" ")
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
            if line.bridge().swerver_stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()).bridge().swerver_lengthOfBytesUsingEncoding(NSUTF8StringEncoding) == 0 {
                stillParsingHeaders = false
                continue
            }
            
            if stillParsingHeaders {
                let components = line.bridge().swerver_componentsSeparatedByString(":").map {
                    str in
                    str.bridge().swerver_stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                }
                if components.count == 2 {
                    headers[components[0]] = components[1]
                }
            } else {
                let trimmed = line.bridge().swerver_stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()).bridge().stringByAppendingString("\n")
                let chunk = NSData(bytes: unsafeBitCast(trimmed.bridge().swerver_cStringUsingEncoding(NSUTF8StringEncoding), UnsafePointer<Void>.self), length: trimmed.bridge().swerver_lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
                    
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

        if let d = data {
	   let str = String(d.map { b in Character(UnicodeScalar(b)) })
            output += "Content-Length: \(str.bridge().swerver_lengthOfBytesUsingEncoding(NSUTF8StringEncoding))\n"
            addHeaders()
            output += "\r\n"
            output += str
        } else {
            output += "Content-Length: 0\n"
            addHeaders()
            output += "\r\n"
        }

	print("Output: \(output)")
        
        let cString = output.swerver_cStringUsingEncoding(NSUTF8StringEncoding)
        let bytes = UnsafePointer<Int8>(cString)
        return NSData(bytes: bytes, length: output.bridge().swerver_lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
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
