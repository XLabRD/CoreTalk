//
//  PubSubService.swift
//  App
//
//  Created by Francisco Lobo on 7/7/19.
//

import Vapor

private enum Verb: String, Codable {
    case subscribe
    case unsubscribe
    case publish
}

private enum EventKind: String, Codable {
    case connect
    case disconnect
    case custom
}

private struct EventRoute: Codable {
    var verb: Verb?
    var domain: String?
    var service: String?
    var kind: EventKind?
}

fileprivate struct Subscription: Equatable {
    var subscriber: Connection
    var service: String?
    var domain:  String?
}

class PubSub: CoreTalkService {
    static var accessPermissionRequired: Bool = true
    static var serviceName: String  = "pubsub"
    static var respondsTo: [String]? = nil
    
    //CORETALKSERVICE
    var manager: ServiceManager?
    var eventsToListen: [CoreTalkEventKind]? = [.connections, .disconnections, .mutations]
    var serviceId: UUID = UUID()
    
    
    private var subscriptions = [Subscription]()
    
    
//    func handle(message: Message, source: inout Connection, pool: ClientManager, req: Request) {
//        if let verb = message.noun {
//            switch verb {
//            case PubSubResponses.subscribe.rawValue:
//                subscribe(message: message, source: source, pool: pool, req: req)
//                break
//            case PubSubResponses.unsubscribe.rawValue:
//                unSubscribe(message: message, source: source, pool: pool, req: req)
//                break
//            default:
//                break
//            }
//        }
//    }
    
    func handle(route: Route, source: inout Connection, pool: ClientManager, req: Request) {
        guard let eventRoute = try? route.decode(to: EventRoute.self), let verb = eventRoute.verb else {
            source.send(object: CoreTalkError(type: .InvalidFormat))
            return
        }
        
        switch verb {
        case .subscribe:
            let subscriber = Subscription(subscriber: source, service: eventRoute.service, domain: eventRoute.domain)
            self.subscriptions.append(subscriber)
            source.send(object: AKN(request: verb.rawValue))
        case .unsubscribe:
            if let address = source.client?.address {
                self.subscriptions.removeAll( where: { $0.subscriber.client?.address == address && $0.service == eventRoute.service && $0.domain == eventRoute.domain })
                source.send(object: AKN(request: verb.rawValue))
            }
        default:
            //TODO!            
            source.send(object: CoreTalkError(type: .InvalidFormat))
            return
        }
        
//
//        switch verb {
//        case .addClient:
//            addClient(adminRoute: adminRoute, source: source, pool: pool, req: req)
//        case .removeClient:
//            removeClient(adminRoute: adminRoute, source: source, pool: pool, req: req)
//        case .addPermission:
//            addPermission(adminRoute: adminRoute, source: source, pool: pool, req: req)
//        case .removePermission:
//            removePermission(adminRoute: adminRoute, source: source, pool: pool, req: req)
//        default:
//            return
//        }
        
        
        
    }

}

extension PubSub {
    func handle(event: CoreTalkEvent) {        
        switch event.kind {
        case .connections:
            break
        case .disconnections:
            if let address = event.sourceConnection?.client?.address {
                self.subscriptions.removeAll( where: { $0.subscriber.client?.address == address })
                print("[events] Removed address: \(address) from pool")
            }
        case .mutations:
            break
        }
    }
}


extension PubSub {
//    struct PubSubMessage: Message {
//        var raw: String?
//        let service: String
//        let kind: String
//    }
    
//    func subscribe(message: Message, source: Connection, pool: ClientManager, req: Request) {
//        if let noun = message.noun {
//            guard let serviceName = message.body?["service"] as? String, let rawKind = message.body?["kind"] as? String else {
//                source.send(object: CoreTalkError(type: .InvalidFormat))
//                return
//            }
//
//            guard let kind = CoreTalkEventKind(rawValue: rawKind) else {
//                source.send(object: CoreTalkError(type: .InvalidFormat))
//                return
//            }
//
//            var subscription = Subscription(subscriber: source, eventKind: kind, service: serviceName, verb: nil)
//
//            if let aVerb = message.body?["verb"] as? String {
//                subscription.verb = aVerb
//            }
//
//            let candidates = self.subscriptions.filter { $0 == subscription }
//
//            if candidates.count > 0 {
//               source.send(object: CoreTalkError(code: 100, text: "Already subscribed to event", domain: "pubsub.err") )
//                return
//            }
//
//
//            self.subscriptions.append(subscription)
//            source.send(object: AKN(request: noun))
//            print (subscriptions)
//        }
//    }
//}
//    func unSubscribe(message: Message, source: Connection, pool: ClientManager, req: Request) {
//        if let noun = message.noun {
//            guard let serviceName = message.body?["service"] as? String, let rawKind = message.body?["kind"] as? String else {
//                source.send(object: CoreTalkError(type: .InvalidFormat))
//                return
//            }
//
//            guard let kind = CoreTalkEventKind(rawValue: rawKind) else {
//                source.send(object: CoreTalkError(type: .InvalidFormat))
//                return
//            }
//
//            var subscription = Subscription(subscriber: source, eventKind: kind, service: serviceName, verb: nil)
//
//            if let aVerb = message.body?["verb"] as? String {
//                subscription.verb = aVerb
//            }
//
//            let candidates = self.subscriptions.filter { $0 == subscription  }
//
//
//            print(candidates)
//            if candidates.count <= 0 {
//                source.send(object: CoreTalkError(code: 101, text: "Not subscribed to event", domain: "pubsub.err") )
//                return
//            }
//
//
//            self.subscriptions.removeAll(where: {$0 == candidates.first})
//            source.send(object: AKN(request: verb))
//        }
//    }
//}
}
