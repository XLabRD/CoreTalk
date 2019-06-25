//
//  CoreError.swift
//  App
//
//  Created by Francisco Lobo on 6/25/19.
//

import Vapor

//setup
fileprivate let DefaultDomain = "com.coretalk.error"
//setup


enum CoreTalkErrorType {
    case InvalidFormat
    case ServiceNotFound
    case PermissionDenied
    case AuthTimeout
    case Unknown
}

struct CoreTalkError: Encodable {
    var error: CoreErrorBody
    
    init(code: Int, text: String) {
        self.error = CoreErrorBody(code: code, text: text, domain: DefaultDomain)
    }
    init(code: Int, text: String, domain: String) {
        self.error = CoreErrorBody(code: code, text: text, domain: domain)
    }
    
    init(type: CoreTalkErrorType) {
        switch type {
        case .InvalidFormat:
            self.error = CoreErrorBody(code: 600, text: "Invalid Format", domain: DefaultDomain)
        case .ServiceNotFound:
            self.error = CoreErrorBody(code: 601, text: "Service not found", domain: DefaultDomain)
        case .PermissionDenied:
            self.error = CoreErrorBody(code: 700, text: "Permission Denied", domain: DefaultDomain)
        case .AuthTimeout:
            self.error = CoreErrorBody(code: 601, text: "Auth Timeout", domain: DefaultDomain)
        case .Unknown:
            self.error = CoreErrorBody(code: 601, text: "Unknown Error", domain: DefaultDomain)
            
        
        }
    }
    
    
}

struct CoreErrorBody: Encodable {
    var code: Int
    var text: String
    var domain: String
}


