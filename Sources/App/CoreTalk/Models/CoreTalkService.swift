//
//  CoreTalkService.swift
//  App
//
//  Created by Francisco Lobo on 6/20/19.
//

import Vapor

enum CoreTalkEventKind: String, Equatable {
    case disconnections
    case connections
    case mutations
}

struct CoreTalkEvent {
    var kind: CoreTalkEventKind
    var sourceConnection: Connection?
    var sourceService: CoreTalkService?
    var changes: [Codable]?
}

protocol CoreTalkService {
    var manager: ServiceManager? { get set }
    static var serviceName: String { get set }
    var eventsToListen: [CoreTalkEventKind]? {get set}
    static var accessPermissionRequired: Bool {get set}
    func handle(route: Route, source: inout Connection, pool:ClientManager, req: Request)
    func handle(event: CoreTalkEvent)
    
}

extension CoreTalkService {
    
    var serviceName: String {
        get  {
            return Self.serviceName
        }
    }
    
    var accessPermissionRequired: Bool {
        get {
            return Self.accessPermissionRequired
        }
    }
    
    func handle(event: CoreTalkEvent) {} //Events
    
}
