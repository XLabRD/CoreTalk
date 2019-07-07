//
//  DefaultService.swift
//  App
//
//  Created by Francisco Lobo on 6/21/19.
//
import Vapor
import FluentSQLite

class Admin: CoreTalkService {
    
    var manager: ServiceManager?
    private enum AdminResponses: String, ServiceRespondable {
        case addClient
        case removeClient
        case listClients
        case listConnections
        case listServices
        case connectionCount
        case kill
        case addPermission
        case removePermission
    }
    
    var responses: Respondable.Type = AdminResponses.self
    
    var notificationSubscriptions: [CoreTalkNotificationType]? =
        [CoreTalkNotificationType.connect,
         CoreTalkNotificationType.disconnect]
    
    static var accessPermissionRequired = true
    static var serviceName: String = "Admin"        
    private var gateKeeper = GateKeeper()
    
    var serviceId = UUID()    
    func handle<T: CoreTalkRepresentable>(message: T, source: inout Connection, pool: ClientManager, req: Request) {
        if (Permission.can(connection: source, .admin, in: self) == false) {
            source.send(object: CoreTalkError(type: .PermissionDenied))
            return
        }
        
        if let verb = message.verb {
            switch verb {
            case AdminResponses.addClient.rawValue:
                addClient(message: message, source: source, pool: pool, req: req)
            case AdminResponses.addClient.rawValue:
                removeClient(message: message, source: source, pool: pool, req: req)
            case AdminResponses.listClients.rawValue:
                listClients(message: message, source: source, pool: pool, req: req)
            case AdminResponses.listConnections.rawValue:
                listConnections(message: message, source: source, pool: pool, req: req)
            case AdminResponses.listServices.rawValue:
                listServices(message: message, source: source, pool: pool, req: req)
            case AdminResponses.connectionCount.rawValue:
                connectionCount(message: message, source: source, pool: pool, req: req)
            case AdminResponses.kill.rawValue:
                killConnection(message: message, source: source, pool: pool, req: req)
            case AdminResponses.addPermission.rawValue:
                addPermission(message: message, source: source, pool: pool, req: req)
            case AdminResponses.removePermission.rawValue:
                removePermission(message: message, source: source, pool: pool, req: req)
            default:
                return
            }
        }
    }
}


extension Admin { //ABC Clients
    
    
    func addPermission<T: CoreTalkRepresentable>(message: T, source: Connection, pool: ClientManager, req: Request) {
        guard let address = message.body?["address"] as? Address, let service = message.body?["service"] as? String, let level = message.body?["level"] as? Int else {
            source.send(object: CoreTalkError(type: .InvalidFormat))
            return
        }
        
        gateKeeper.getClient(from: address, req: req) { client in
            
            guard let client = client else {
                source.send(object: CoreTalkError(code: 101, text: "Client not found", domain: "auth.err"))
                return
            }
            
            guard let authority = Permission.Authority(rawValue: level) else {
                source.send(object: CoreTalkError(code: 102, text: "Invalid Authority", domain: "auth.err"))
                return
            }
            
            let permission = Permission(authority:authority, serviceName: service)
            
            if (client.permissions.contains { $0 == permission }) {
                source.send(object: CoreTalkError(code: 103, text: "Permission already assigned", domain: "auth.err"))
                return
            }
            
            
            client.permissions += [permission]
            
            
            _ = client.save(on: req).map { newClient in
                source.send(object: newClient)
                let activeClient = pool[address]
                activeClient?.client = newClient
            }
        }
    }
    
    func removePermission<T: CoreTalkRepresentable>(message: T, source: Connection, pool: ClientManager, req: Request) {
        guard let address = message.body?["address"] as? Address, let service = message.body?["service"] as? String, let level = message.body?["level"] as? Int else {
            source.send(object: CoreTalkError(type: .InvalidFormat))
            return
        }
        
        gateKeeper.getClient(from: address, req: req) { client in
            
            guard let client = client else {
                source.send(object: CoreTalkError(code: 101, text: "Client not found", domain: "auth.err"))
                return
            }
            
            guard let authority = Permission.Authority(rawValue: level) else {
                source.send(object: CoreTalkError(code: 102, text: "Invalid Authority", domain: "auth.err"))
                return
            }
            
            let permission = Permission(authority:authority, serviceName: service)
            
            if (client.permissions.contains { $0 == permission }) == false {
                source.send(object: CoreTalkError(code: 103, text: "Permission not assigned to client", domain: "auth.err"))
                return
            }
            
            client.permissions.removeAll(where:{ $0 == permission})
            
            _ = client.save(on: req).map { newClient in
                source.send(object: newClient)
                let activeClient = pool[address]
                activeClient?.client = newClient
            }
        }
    }
    
    func removeClient<T: CoreTalkRepresentable>(message: T, source: Connection, pool: ClientManager, req: Request) {
        guard let desiredAddress = message.body?["address"] as? Address else {
            source.send(object: CoreTalkError(type: .InvalidFormat))
            return
        }
        
        if desiredAddress == source.client?.address {
            source.send(object: CoreTalkError(code: 104, text: "Can't delete your own address", domain: "auth.err"))
            return
        }
        
        
        self.gateKeeper.getClient(from: desiredAddress, req: req) { client in
            guard let client = client else {
                source.send(object: CoreTalkError(code: 105, text: "Client not found", domain: "auth.err"))
                return
            }
            _ =
                client.delete(on: req).map {
                    source.send(object: AKN(request: message.verb))
            }
        }
    }
    
    func addClient<T: CoreTalkRepresentable>(message: T, source: Connection, pool: ClientManager, req: Request) {
        guard let desiredAddress = message.body?["address"] as? Address else {
            source.send(object: CoreTalkError(type: .InvalidFormat))
            return
        }
        
        self.gateKeeper.getClient(from: desiredAddress, req: req) { client in
            
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
    
    func listServices<T: CoreTalkRepresentable>(message: T, source: Connection, pool: ClientManager, req: Request) {
        source.send(object: ["services":self.manager?.serviceNames()])
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
            source.send(object: ["clients":clean])
        }
    }
    
    func listConnections<T: CoreTalkRepresentable>(message: T, source: Connection, pool: ClientManager, req: Request) {
        source.send(object: ["connections":pool.list()])
    }
    
    func connectionCount<T: CoreTalkRepresentable>(message: T, source: Connection, pool: ClientManager, req: Request) {
        source.send(object: ["connectionCount":pool.count])
    }
    
    func killConnection<T: CoreTalkRepresentable>(message: T, source: Connection, pool: ClientManager, req: Request) {
        guard let desiredAddress = message.body?["address"] as? Address else {
            source.send(object: CoreTalkError(type: .InvalidFormat))
            return
        }
        
        let conn = pool[desiredAddress]
        
        if let conn = conn {
            conn.send(object: ServerMessage(message: "Connection terminated by peer", code: 0))
            conn.socket.close()
            source.send(object: AKN(request: message.verb))
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
