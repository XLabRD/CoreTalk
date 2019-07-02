//
//  DefaultService.swift
//  App
//
//  Created by Francisco Lobo on 6/21/19.
//

import Vapor



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
    
    func handle<T: CoreTalkRepresentable>(message: T, source: inout Connection, pool: ClientManager, req: Request) {
        if let verb = message.verb {
            switch verb {
            case "ping":
                let pong = Pong()
                source.send(object: pong)
            default:
                return
            }
            
        }
    }
}


