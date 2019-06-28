//
//  CoreError.swift
//  App
//
//  Created by Francisco Lobo on 6/25/19.
//

import Vapor

enum CoreTalkErrorType:Int, Codable {
    case InvalidFormat
    case ServiceNotFound
    case PermissionDenied
    case AuthTimeout
    case AddressTaken
    case AlreadyAuth
    case Unknown
}

struct CoreTalkError: Encodable {
    var error: CoreErrorBody
    
    init(code: Int, text: String) {
        self.error = CoreErrorBody(code: code, text: text, domain: CoreTalkSettings.ErrorDefaultDomain)
    }
    init(code: Int, text: String, domain: String) {
        self.error = CoreErrorBody(code: code, text: text, domain: domain)
    }
    
    init(type: CoreTalkErrorType) {
        switch type {
        case .InvalidFormat:
            self.error = CoreErrorBody(code: 600, text: "Invalid Format", domain: CoreTalkSettings.ErrorDefaultDomain)
        case .ServiceNotFound:
            self.error = CoreErrorBody(code: 601, text: "Service not found", domain: CoreTalkSettings.ErrorDefaultDomain)
        case .PermissionDenied:
            self.error = CoreErrorBody(code: 700, text: "Permission Denied", domain: CoreTalkSettings.ErrorDefaultDomain)
        case .AuthTimeout:
            self.error = CoreErrorBody(code: 601, text: "Auth Timeout", domain: CoreTalkSettings.ErrorDefaultDomain)
        case .AddressTaken:
            self.error = CoreErrorBody(code: 602, text: "Address Taken", domain: CoreTalkSettings.ErrorDefaultDomain)
        case .AlreadyAuth:
            self.error = CoreErrorBody(code: 602, text: "Already authenticated", domain: CoreTalkSettings.ErrorDefaultDomain)
        case .Unknown:
            self.error = CoreErrorBody(code: 800, text: "Unknown Error", domain: CoreTalkSettings.ErrorDefaultDomain)
            
        
        }
    }
    
    
}

struct CoreErrorBody: Encodable {
    var code: Int
    var text: String
    var domain: String
}


