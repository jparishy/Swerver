//
//  HTTP11.swift
//  Swerver
//
//  Created by Julius Parishy on 12/5/15.
//  Copyright © 2015 Julius Parishy. All rights reserved.
//

import Foundation

#if os(Linux)
import Glibc
#endif

public class HTTP11 : HTTPVersion {
    let dataString: String?
    
    public required init(rawRequest: NSData) {
#if os(Linux)
	if let bytes = NSString(bytes: rawRequest.bytes, length: rawRequest.length, encoding: NSUTF8StringEncoding)?.swerver_cStringUsingEncoding(NSUTF8StringEncoding) {
		dataString = String(bytes.map { b in Character(UnicodeScalar(b)) })
	} else {
		dataString = nil
	}
#else
        dataString = NSString(bytes: rawRequest.bytes, length: rawRequest.length, encoding: NSUTF8StringEncoding) as? String
#endif
    }
    
    public func request() -> Request? {
        if let lines = dataString?.bridge().swerver_componentsSeparatedByString("\n") {
            if let first = lines.first {
                let parts = first.bridge().swerver_componentsSeparatedByString(" ")
                if parts.count == 3, let method = HTTPMethod.fromString(parts[0]) {
                    let rest = Array(lines.dropFirst())
                    let (headers, requestBody) = parseHeadersAndBodyFromRestOfLines(rest)
                    return Request(method: method, path: parts[1], headers: headers, requestBody: requestBody)
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
                let scanner = NSScanner(string: line)
                
                if let key = scanner.scanUpToString(":") {
                    let value = line.bridge().substringFromIndex(scanner.scanLocation + 1).swerver_stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                    headers[key] = value
                }
            } else {
                let trimmed = line.bridge().swerver_stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()).bridge().stringByAppendingString("\n")
                let bytes = trimmed.bridge().swerver_cStringUsingEncoding(NSUTF8StringEncoding)
                let chunk = NSData(bytes: bytes, length: bytes.count)
        
                data?.appendData(chunk)
            }
        }
        
        if let d = data where d.length == 0 {
            data = nil
        }
        
        return (headers, data)
    }
    
    public func response(statusCode: StatusCode, headers: Headers, data: NSData?) -> NSData {
    
        var output = ""
        output += "HTTP/1.1 \(statusCode.statusCodeString)\n"
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
            output += "Content-Length: \(d.length)\n"
            addHeaders()
            output += "\r\n"
        } else {
            output += "Content-Length: 0\n"
            addHeaders()
            output += "\r\n"
        }

        let cString = output.swerver_cStringUsingEncoding(NSUTF8StringEncoding)
        let bytes = UnsafePointer<Int8>(cString)
        
        let outData =  NSMutableData(bytes: bytes, length: output.bridge().swerver_lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
        
        if let data = data {
            outData.appendData(data)
        }
        
        return outData
    }
}
