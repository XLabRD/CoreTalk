//
//  DefaultService.swift
//  App
//
//  Created by Francisco Lobo on 6/21/19.
//
import Vapor
import FluentSQLite


class Admin: CoreTalkService {
    var notificationSubscriptions: [CoreTalkNotificationType]? =
        [CoreTalkNotificationType.connect,
         CoreTalkNotificationType.disconnect]
    
    static var accessPermissionRequired = true
    static var serviceName: String = "Admin"
    
    private var gateKeeper = GateKeeper()
    
    var serviceId = UUID()
    var respondsTo = ["addClient", "removeClient", "listClients", "listConnections",  "connectionCount", "kill"]
    
    func handle<T: CoreTalkRepresentable>(message: T, source: inout Connection, pool: ClientManager, req: Request) {
        if let verb = message.verb {
            switch verb {
            case "addClient":
                addClient(message: message, source: source, pool: pool, req: req)
            case "removeClient":
                removeClient(message: message, source: source, pool: pool, req: req)
            case "listClients":
                listClients(message: message, source: source, pool: pool, req: req)
            case "listConnections":
                listConnections(message: message, source: source, pool: pool, req: req)
            case "connectionCount":
                connectionCount(message: message, source: source, pool: pool, req: req)
            case "kill":
                killConnection(message: message, source: source, pool: pool, req: req)
            default:
                return
            }
        }
    }
}


extension Admin { //ABC Clients
    func removeClient<T: CoreTalkRepresentable>(message: T, source: Connection, pool: ClientManager, req: Request) {
        guard let desiredAddress = message.body?["address"] as? Address else {
            source.send(object: CoreTalkError(type: .InvalidFormat))
            return
        }
        
        if desiredAddress == source.client?.address {
            source.send(object: CoreTalkError(code: 104, text: "Can't delete your own address", domain: "auth.err"))
            return
        }
        
        
        gateKeeper.getClient(from: desiredAddress, req: req) { client in
            guard let client = client else {
                source.send(object: CoreTalkError(code: 105, text: "Client not found", domain: "auth.err"))
                return
            }
            _ =
                client.delete(on: req).map {
                    source.send(object: akn())
            }
        }
    }
    
    func addClient<T: CoreTalkRepresentable>(message: T, source: Connection, pool: ClientManager, req: Request) {
        guard let desiredAddress = message.body?["address"] as? Address else {
            source.send(object: CoreTalkError(type: .InvalidFormat))
            return
        }
        
        gateKeeper.getClient(from: desiredAddress, req: req) { client in
            
            if client != nil {
                source.send(object: CoreTalkError(code: 100, text: "Client already registered", domain: "auth.err"))
                return
            }
            
            let myClient = Client()
            myClient.address = desiredAddress
            _ = myClient.save(on: req).map { newClient in
                source.send(object: newClient)
            }
        }
    }
    
    func listClients<T: CoreTalkRepresentable>(message: T, source: Connection, pool: ClientManager, req: Request) {
        _ = Client.query(on: req).all().map { clients in
            var clean = [String]()
            
            for client in clients {
                guard let address = client.address else {
                    break
                }
                
               clean.append(address)
                
            }
            source.send(object: clean)
        }
    }
    
    func listConnections<T: CoreTalkRepresentable>(message: T, source: Connection, pool: ClientManager, req: Request) {
        var clean = [String]()
        
        for conn in pool.all() {
            guard let address = conn.client?.address else {
                break
            }
            
            clean.append(address)
            
        }
        source.send(object: clean)
    }
    
    func connectionCount<T: CoreTalkRepresentable>(message: T, source: Connection, pool: ClientManager, req: Request) {
        source.send(object: ["count":pool.all().count])
    }
    
    func killConnection<T: CoreTalkRepresentable>(message: T, source: Connection, pool: ClientManager, req: Request) {
        guard let desiredAddress = message.body?["address"] as? Address else {
            source.send(object: CoreTalkError(type: .InvalidFormat))
            return
        }
        
        let conn = pool.findConnection(from: desiredAddress)
        
        if let conn = conn {
            conn.send(object: ServerMessage(message: "Connection terminated by peer", code: 0))
            conn.socket.close()
            source.send(object: akn())
            return
        }
        
        source.send(object: CoreTalkError(type: .NotFound))
    }
    
    
}



// Protocol duties
extension Admin {
    func handleNotification(notification: CoreTalkNotificationType, for connection: Connection) {
        switch notification {
        case .connect:
            break
        case .disconnect:
            break
        }
    }
}
