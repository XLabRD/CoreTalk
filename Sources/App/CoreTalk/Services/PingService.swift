//
//  DefaultService.swift
//  App
//
//  Created by Francisco Lobo on 6/21/19.
//

import Vapor

class Ping: CoreTalkService {
    var manager: ServiceManager?
    private enum PingResponses: String, ServiceRespondable {
        case ping
    }
    var responses: Respondable.Type = PingResponses.self
    
    var eventsToListen: [CoreTalkEventKind]?
    static var serviceName: String = "Ping"
    static var accessPermissionRequired = true
    var serviceId = UUID()
    
    internal struct PongBody: Encodable {
        let timeStamp = Date().ctStringValue()
    }
    
    internal struct Pong: Encodable {
        let pong = PongBody()
    }
    
    
    func handle<T: CoreTalkRepresentable>(message: T, source: inout Connection, pool: ClientManager, req: Request) {
        if let verb = message.verb {
            switch verb {
            case PingResponses.ping.rawValue:
                let pong = Pong()
                source.send(object: pong)
            default:
                return
            }
            
        }
    }
}


