//
//  CoreTalkService.swift
//  App
//
//  Created by Francisco Lobo on 6/20/19.
//

import Vapor


enum CoreTalkNotificationType {
        case Disconnect
        case Connect
}

protocol CoreTalkService {    
    static var serviceName: String { get set }
    var serviceId: UUID { get set }
    var respondsTo: [String] { get set }
    static var permissionRequired: Bool {get set}     
    
    func subscribeTo(notification: CoreTalkNotificationType) -> Bool
    func handle(message:CoreTalkMessage, source: inout Connection, pool:ConnectionPool)
}

extension CoreTalkService {
    var serviceName: String {
        get {
            return type(of: self).serviceName
        }
    }
    
    var permissionRequired: Bool {
        get {
            return type(of: self).permissionRequired
        }
    }
    
    func subscribeTo(notification: CoreTalkNotificationType) -> Bool {
        return false
    }
    
        
}
