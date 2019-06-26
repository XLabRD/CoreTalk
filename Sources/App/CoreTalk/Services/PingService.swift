//
//  DefaultService.swift
//  App
//
//  Created by Francisco Lobo on 6/21/19.
//

import Foundation



class Ping: CoreTalkService {
    var notificationSubscriptions: [CoreTalkNotificationType]?
    static var serviceName: String = "PingPong"
    static var accessPermissionRequired = true
    var serviceId = UUID()
    
    internal struct PongBody: Encodable {
        let timeStamp = Date().ctStringValue()
    }
    
    internal struct Pong: Encodable {
        let pong = PongBody()
    }
    
    var respondsTo = ["ping"]
    
    func handle(message: CoreTalkMessage, source: inout Connection, pool: ConnectionManager) {
        if let verb = message.verb {
            switch verb {
            case "ping":
                let pong = Pong()
                source.send(WireMessage.encode(object: pong))
            default:
                return
            }
            
        }
    }
}


