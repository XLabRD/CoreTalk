//
//  DefaultService.swift
//  App
//
//  Created by Francisco Lobo on 6/21/19.
//

import Foundation



class Ping: CoreTalkService {
    
    
    static var serviceName: String = "PingPong"
    static var permissionRequired = true
    var serviceId = UUID()
    
    internal struct PongBody: Encodable {
        let timeStamp = Date().ctStringValue()
    }
    
    internal struct Pong: Encodable {
        let pong = PongBody()
    }
    
    var respondsTo = ["ping"]
    
    func handle(message: CoreTalkMessage, source: inout Connection, pool: ConnectionPool) {
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


