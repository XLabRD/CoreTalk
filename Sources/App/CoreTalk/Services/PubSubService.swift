//
//  PubSubService.swift
//  App
//
//  Created by Francisco Lobo on 7/7/19.
//

import Vapor

fileprivate struct Subscription: Equatable {
    var subscriber: Connection
    var eventKind: CoreTalkEventKind
    var service: String
    var verb:  String?
}

class PubSub: CoreTalkService {
//    private enum PubSubResponses: String, ServiceRespondable {
//        case subscribe
//        case unsubscribe
//    }
//    var responses: Respondable.Type = PubSubResponses.self
    
    static var accessPermissionRequired: Bool = true
    
    static var serviceName: String  = "PubSub"
    
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
        
    }

}

extension PubSub {
    func handleEvent(event: CoreTalkEvent, for connection: Connection) {
        switch event.kind {
        case .connections:
            break
        case .disconnections:
            if let address = connection.client?.address {
                self.subscriptions.removeAll( where: { $0.subscriber.client?.address == address })
                print("[AuthService] Removed address: \(address) from pool")
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
