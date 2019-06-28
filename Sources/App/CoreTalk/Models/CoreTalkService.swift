//
//  CoreTalkService.swift
//  App
//
//  Created by Francisco Lobo on 6/20/19.
//

import Vapor


enum CoreTalkNotificationType {
    case disconnect
    case connect
}


protocol CoreTalkService {
    static var serviceName: String { get set }
    var notificationSubscriptions: [CoreTalkNotificationType]? {get set}
    var serviceId: UUID { get set }
    var respondsTo: [String] { get set }
    static var accessPermissionRequired: Bool {get set}
    
    func handle(message:CoreTalkMessage, source: inout Connection, pool:ClientManager, req: Request)
    func handleNotification(notification: CoreTalkNotificationType, for connection: Connection)
}

extension CoreTalkService {
        
    var serviceName: String {
        get {
            return type(of: self).serviceName
        }
    }
    
    var accessPermissionRequired: Bool {
        get {
            return type(of: self).accessPermissionRequired
        }
    }
    
    func handleNotification(notification: CoreTalkNotificationType, for connection: Connection) {}    
}
