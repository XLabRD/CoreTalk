//
//  CoreTalkService.swift
//  App
//
//  Created by Francisco Lobo on 6/20/19.
//

import Vapor


public enum CoreTalkNotificationType {
    case disconnect
    case connect
}


public protocol Respondable {
    static func AllCases() -> [String]
}

public extension Respondable where Self : RawRepresentable, Self: CaseIterable, Self.RawValue == String {
    static func AllCases() -> [String] {
        let allCases = Self.allCases
        var list = [String]()
        for aCase in allCases {
            list += [aCase.rawValue]
        }
        
        return list
    }
}

public typealias ServiceRespondable = Respondable & CaseIterable




protocol CoreTalkService {
    var manager: ServiceManager? { get set }
    static var serviceName: String { get set }
    var notificationSubscriptions: [CoreTalkNotificationType]? {get set}
    var serviceId: UUID { get set }
    var responses:Respondable.Type { get set }
    static var accessPermissionRequired: Bool {get set}
    func handle<T: CoreTalkRepresentable>(message: T, source: inout Connection, pool:ClientManager, req: Request)
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
