//
//  DefaultService.swift
//  App
//
//  Created by Francisco Lobo on 6/21/19.
//

import Vapor

class Ping: CoreTalkService {
    var manager: ServiceManager?

    var eventsToListen: [CoreTalkEventKind]?
    static var serviceName: String = "Ping"
    static var accessPermissionRequired = true
    var serviceId = UUID()
    
    private struct PongBody: Encodable {
        let timeStamp = Date().ctStringValue()
    }
    
    private struct Pong: Encodable {
        let pong = PongBody()
    }
    
    func handle(route: Route, source: inout Connection, pool: ClientManager, req: Request) {
        source.send(object: Pong())
    }

    
}


