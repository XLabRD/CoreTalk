//
//  DefaultService.swift
//  App
//
//  Created by Francisco Lobo on 6/21/19.
//
import Foundation


class Authentication: CoreTalkService {
    static var permissionRequired = false
    static var serviceName: String = "Authentication"
    var defaultAccessPermissions = [CoreTalkService.Type]()
    
    var serviceId = UUID()
    
    var respondsTo = ["auth"]
    
    func handle(message: CoreTalkMessage, source: inout Connection, pool: ConnectionManager) {
        if let verb = message.verb {
            switch verb {
            case "auth":
                source.confirmed = true
                source.address = Address("1.1.1")
                source.send(object: source.address!)
            default:
                return
            }
        }
    }
    
    func defaultPermissions(for source: inout Connection) {
        source.permissions.append(Permission.newPermission(for: Ping.self, to: .access))
    }
    
    
    func mutate(connection: inout Connection) -> Connection {
        return connection
    }
}
