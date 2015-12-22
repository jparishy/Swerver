//
//  Layout.swift
//  Swerver
//
//  Created by Julius Parishy on 12/21/15.
//  Copyright © 2015 Julius Parishy. All rights reserved.
//

import Foundation

enum Tab {
    case Home
    case About
    case Contributing
    
    var href: String {
        switch self {
        case .Home: return "/"
        case .About: return "/"
        case .Contributing: return "/"
        }
    }
    
    var title: String {
        switch self {
        case .Home: return "Home"
        case .About: return "About"
        case .Contributing: return "Contributing"
        }
    }
    
    static func all() -> [Tab] {
        return [.Home, .About, .Contributing]
    }
}

class BootstrapLayout {
    static func render(t: Template.Renderer, activeTab: Tab, inside: (Template.Renderer) -> ()) {
        t.html { t in
            t.head { t in
                t.link(attrs: [
                    "rel"         : "stylesheet",
                    "href"        : "https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap.min.css",
                    "integrity"   : "sha384-1q8mTJOASx8j1Au+a5WDVnPi2lkFfwwEAa8hDDdjZlpLegxhjVME1fgjWPGmkzs7",
                    "crossorigin" : "anonymous"
                ])
                
                t.link(attrs: [
                    "rel"         : "stylesheet",
                    "href"        : "https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap-theme.min.css",
                    "integrity"   : "sha384-fLW2N01lMqjakBkx3l/M9EahuwpSfeNvV63J5ezn3uZzapT0u7EYsXMjQV+0En5r",
                    "crossorigin" : "anonymous"
                ])
                
                t.script(attrs: [
                    "src" : "https://ajax.googleapis.com/ajax/libs/jquery/1.11.3/jquery.min.js",
                ])
                
                t.script(attrs: [
                    "src"         : "https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/js/bootstrap.min.js",
                    "integrity"   : "sha384-0mSbJDEHialfmuBBQP6A4Qrprq5OVfW37PRR3j5ELqxss1yVqOtnepnHVP9aJ7xS",
                    "crossorigin" : "anonymous"
                ])
            }
            
            t.body { t in
                t.div(cssClass: "container") { t in
                    t.tag("nav", cssClass: "navbar navbar-default") { t in
                        t.div(cssClass: "container-fluid") { t in
                            t.div(cssClass: "navbar-header") { t in
                                
                                let attrs = [
                                    "type" : "button",
                                    "data-toggle" : "collapse",
                                    "data-target" : "#navbar",
                                    "aria-expanded" : "false",
                                    "aria-controls" : "navbar"
                                ]
                                
                                t.tag("button", cssClass: "navbar-toggle collapsed", attrs: attrs) { t in
                                    t.tag("span", cssClass: "sr-only", contents: "Toggle Navigation")
                                    t.tag("span", cssClass: "icon-bar")
                                    t.tag("span", cssClass: "icon-bar")
                                    t.tag("span", cssClass: "icon-bar")
                                }
                                
                                t.a("/", cssClass: "navbar-brand", contents: "Swerver")
                            }
                            
                            t.div(attrs: ["id" : "navbar"], cssClass: "navbar-collapse collapse") { t in
                                t.tag("ul", cssClass: "nav navbar-nav") { t in
                                    for tab in Tab.all() {
                                        let cssClass: String? = (tab == activeTab) ? "active" : nil
                                        t.tag("li", cssClass: cssClass) { t in
                                            t.a(tab.href, contents: tab.title)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    inside(t)
                }
            }
        }
    }
}
