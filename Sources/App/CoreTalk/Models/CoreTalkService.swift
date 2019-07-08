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
    var sourceConection: Connection?
    var sourceService: CoreTalkService?
    var changes: [Codable]?
}

//enum CoreTalkEvent: Equatable {
//    case disconnect
//    case connect
//    case mutate(service: CoreTalkService?, changes:[Codable]?)
//
//    public static func == (lhs: CoreTalkEvent, rhs: CoreTalkEvent) -> Bool {
//        switch (lhs, rhs) {
//        case (.disconnect, .disconnect):
//            return true
//        case (.connect, .connect):
//            return true
//        case (let .mutate(leftMutation, _),
//              let .mutate(rightMutation, _)):
//
//            if (leftMutation?.serviceName == rightMutation?.serviceName) {
//                return true
//            }
//
//            return false
//        default:
//            return false
//        }
//
//    }
//}


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
    var eventsToListen: [CoreTalkEventKind]? {get set}
    var serviceId: UUID { get set }
    var responses:Respondable.Type { get set }
    static var accessPermissionRequired: Bool {get set}
    func handle<T: CoreTalkRepresentable>(message: T, source: inout Connection, pool:ClientManager, req: Request)
    func handle(event: CoreTalkEvent)
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
    
    func handle(event: CoreTalkEvent) {}
    
}
