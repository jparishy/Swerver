//
//  Template.swift
//  Swerver
//
//  Created by Julius Parishy on 12/17/15.
//  Copyright © 2015 Julius Parishy. All rights reserved.
//

import Foundation

class Template {
    
    internal var parent: Template?
    
    enum Error : ErrorType {
        case NoParentContext
    }
    
    class Renderer {
        private var _string: String = ""
        private var result: String {
            return _string
        }
        
        let flash: [String:String]
        
        init(flash: [String:String] = [:]) {
            self.flash = flash
        }
        
        func str(str: String) {
            _string += str;
        }
        
        func tag(tag: String, contents: String? = nil, cssClass: String? = nil, attrs: [String:String]? = nil, shouldClose: Bool = true, inner: ((Renderer) -> ())? = nil) {
            
            var allAttrs = attrs ?? [:]
            
            if let cssClass = cssClass {
                allAttrs["class"] = cssClass
            }
            
            let attrsString: String
            if allAttrs.count > 0 {
                var str = " "
                
                var index = 0
                for (k,v) in allAttrs {
                    
                    str += "\(k)=\"\(v)\""
                    if index < (allAttrs.count - 1) {
                        str += " "
                    }
                    
                    index += 1
                }
                
                attrsString = str
            } else {
                attrsString = ""
            }
            
            let innerString: String
            if let inner = inner {
                let innerRenderer = Renderer(flash: flash)
                inner(innerRenderer)
                innerString = innerRenderer.result
            } else {
                innerString = ""
            }
            
            let contentsString: String = contents ?? ""
            
            let close = shouldClose ? "</\(tag)>" : ""
            str("<" + tag + attrsString + ">" + contentsString + innerString + close)
        }
        
        func html(contents: String? = nil, cssClass: String? = nil, attrs: [String:String]? = nil, inner: ((Renderer) -> ())? = nil) {
            tag("html", contents: contents, cssClass: cssClass, attrs: attrs, inner: inner)
        }
        
        func head(contents: String? = nil, cssClass: String? = nil, attrs: [String:String]? = nil, inner: ((Renderer) -> ())? = nil) {
            tag("head", contents: contents, cssClass: cssClass, attrs: attrs, inner: inner)
        }
        
        func link(contents: String? = nil, cssClass: String? = nil, attrs: [String:String]? = nil, inner: ((Renderer) -> ())? = nil) {
            tag("link", contents: contents, cssClass: cssClass, attrs: attrs, inner: inner, shouldClose: false)
        }
        
        func script(contents: String? = nil, cssClass: String? = nil, attrs: [String:String]? = nil, inner: ((Renderer) -> ())? = nil) {
            tag("script", contents: contents, cssClass: cssClass, attrs: attrs, inner: inner)
        }
        
        func body(contents: String? = nil, cssClass: String? = nil, attrs: [String:String]? = nil, inner: ((Renderer) -> ())? = nil) {
            tag("body", contents: contents, cssClass: cssClass, attrs: attrs, inner: inner)
        }
        
        func h1(contents: String? = nil, cssClass: String? = nil, attrs: [String:String]? = nil, inner: ((Renderer) -> ())? = nil) {
            tag("h1", contents: contents, cssClass: cssClass, attrs: attrs, inner: inner)
        }
        
        func h2(contents: String? = nil, cssClass: String? = nil, attrs: [String:String]? = nil, inner: ((Renderer) -> ())? = nil) {
            tag("h2", contents: contents, cssClass: cssClass, attrs: attrs, inner: inner)
        }
        
        func h3(contents: String? = nil, cssClass: String? = nil, attrs: [String:String]? = nil, inner: ((Renderer) -> ())? = nil) {
            tag("h3", contents: contents, cssClass: cssClass, attrs: attrs, inner: inner)
        }
        
        func h4(contents: String? = nil, cssClass: String? = nil, attrs: [String:String]? = nil, inner: ((Renderer) -> ())? = nil) {
            tag("h4", contents: contents, cssClass: cssClass, attrs: attrs, inner: inner)
        }
        
        func h5(contents: String? = nil, cssClass: String? = nil, attrs: [String:String]? = nil, inner: ((Renderer) -> ())? = nil) {
            tag("h5", contents: contents, cssClass: cssClass, attrs: attrs, inner: inner)
        }
        
        func p(contents: String? = nil, cssClass: String? = nil, attrs: [String:String]? = nil, inner: ((Renderer) -> ())? = nil) {
            tag("p", contents: contents, cssClass: cssClass, attrs: attrs, inner: inner)
        }
        
        func div(contents: String? = nil, cssClass: String? = nil, attrs: [String:String]? = nil, inner: ((Renderer) -> ())? = nil) {
            tag("div", contents: contents, cssClass: cssClass, attrs: attrs, inner: inner)
        }
        
        func a(href: String, contents: String? = nil, cssClass: String? = nil, attrs: [String:String]? = nil, inner: ((Renderer) -> ())? = nil) {
            var allAttrs = attrs ?? [:]
            allAttrs["href"] = href
            tag("a", contents: contents, cssClass: cssClass, attrs: allAttrs, inner: inner)
        }
        
        func form(action: String, method: String? = nil, contents: String? = nil, cssClass: String? = nil, attrs: [String:String]? = nil, inner: ((Renderer) -> ())? = nil) {
            var allAttrs = attrs ?? [:]
            allAttrs["action"] = action
            allAttrs["method"] = method ?? "post"
            
            tag("form", contents: contents, cssClass: cssClass, attrs: allAttrs, inner: inner)
        }
        
        func label(contents: String? = nil, cssClass: String? = nil, attrs: [String:String]? = nil, inner: ((Renderer) -> ())? = nil) {
            tag("label", contents: contents, cssClass: cssClass, attrs: attrs, inner: inner)
        }
        
        func input(type: String, name: String?, value: String? = nil, contents: String? = nil, cssClass: String? = nil, attrs: [String:String]? = nil, inner: ((Renderer) -> ())? = nil) {
            var allAttrs = attrs ?? [:]
            allAttrs["type"] = type
            
            if let name = name {
                allAttrs["name"] = name
            }
            
            if let value = value {
                allAttrs["value"] = value
            }
            
            tag("input", contents: contents, cssClass: cssClass, attrs: allAttrs, inner: inner)
        }
        
        func text_field(name: String, value: String? = nil, contents: String? = nil, cssClass: String? = nil, attrs: [String:String]? = nil, inner: ((Renderer) -> ())? = nil) {
            input("text", name: name, value: value, contents: contents, cssClass: cssClass, attrs: attrs, inner: inner)
        }
        
        func secure_text_field(name: String, value: String? = nil, contents: String? = nil, cssClass: String? = nil, attrs: [String:String]? = nil, inner: ((Renderer) -> ())? = nil) {
            input("password", name: name, value: value, contents: contents, cssClass: cssClass, attrs: attrs, inner: inner)
        }
        
        func submit(value: String? = nil, name: String? = nil, contents: String? = nil, cssClass: String? = nil, attrs: [String:String]? = nil, inner: ((Renderer) -> ())? = nil) {
            input("submit", name: name, value: value, contents: contents, cssClass: cssClass, attrs: attrs, inner: inner)
        }
        
        func renderChild(view: View) {
        
        }
    }
    
    static func render(flash: [String:String] = [:], renderFunc: (Renderer) -> ()) -> String {
        let renderer = Renderer(flash: flash)
        renderFunc(renderer)
    
        return renderer.result
    }
}
