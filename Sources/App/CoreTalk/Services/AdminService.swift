//
//  DefaultService.swift
//  App
//
//  Created by Francisco Lobo on 6/21/19.
//
import Vapor
import FluentSQLite

class Admin: CoreTalkService {
    
    //Auth Service Message Models
    private struct AdminRoute: Codable {
        var client: ParamClient?
        var permission: ParamPermission?
        var verb: Verb?
    }
    
    private struct ParamClient: Codable {
        var address: Address?
    }
    
    private struct ParamPermission: Codable {
        var serviceName: String?
        var level: Int?
    }
    
    private enum Verb: String, Codable {
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
    
    var manager: ServiceManager?
    
    var eventsToListen: [CoreTalkEventKind]? =
        [.connections,
         .disconnections] //Subscribe to this two events. (We need both)
    
    static var accessPermissionRequired = true
    static var serviceName: String = "admin"
    private var gateKeeper = GateKeeper()
    static var respondsTo: [String]? = nil
    
    var serviceId = UUID()    
    
    func handle(route: Route, source: inout Connection, pool: ClientManager, req: Request) {
        if (Permission.can(connection: source, .admin, in: self) == false) {
            source.send(object: CoreTalkError(type: .PermissionDenied))
            return
        }
        
        
        guard let adminRoute = try? route.decode(to: AdminRoute.self), let verb = adminRoute.verb else {
            source.send(object: CoreTalkError(type: .InvalidFormat))
            return
        }
        
        
        switch verb {
        case .addClient:
            addClient(adminRoute: adminRoute, source: source, pool: pool, req: req)
        case .removeClient:
            removeClient(adminRoute: adminRoute, source: source, pool: pool, req: req)
        case .addPermission:
            addPermission(adminRoute: adminRoute, source: source, pool: pool, req: req)
        case .removePermission:
            removePermission(adminRoute: adminRoute, source: source, pool: pool, req: req)
        default:
            return
        }
        
    }
}


extension Admin { //ABC Clients
    
    private func addPermission(adminRoute: AdminRoute, source: Connection, pool: ClientManager, req: Request) {
                
        guard let address = adminRoute.client?.address, let serviceName = adminRoute.permission?.serviceName, let level = adminRoute.permission?.level else {
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
            
            let permission = Permission(authority:authority, serviceName: serviceName)
            
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
    
    private func removePermission(adminRoute: AdminRoute, source: Connection, pool: ClientManager, req: Request) {
        
        guard let address = adminRoute.client?.address, let serviceName = adminRoute.permission?.serviceName, let level = adminRoute.permission?.level else {
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
            
            let permission = Permission(authority:authority, serviceName: serviceName)
            
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
    
    
    private func removeClient(adminRoute: AdminRoute, source: Connection, pool: ClientManager, req: Request) {
        guard let desiredAddress = adminRoute.client?.address else {
            source.send(object: CoreTalkError(type: .InvalidFormat))
            return
        }
        
        self.gateKeeper.getClient(from: desiredAddress, req: req) { client in
            guard let client = client else {
                source.send(object: CoreTalkError(code: 105, text: "Client not found", domain: "auth.err"))
                return
            }
            _ =
                client.delete(on: req).map {
                    source.send(object: AKN(request: adminRoute.verb?.rawValue ?? "Unknown"))
            }
        }
        
    }
    
    private func addClient(adminRoute: AdminRoute, source: Connection, pool: ClientManager, req: Request) {
        guard let desiredAddress = adminRoute.client?.address else {
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
    
   private func listServices(adminRoute: AdminRoute, source: Connection, pool: ClientManager, req: Request) {
        source.send(object: ["services":self.manager?.serviceNames()])
    }
    
  private func listClients(adminRoute: AdminRoute, source: Connection, pool: ClientManager, req: Request) {
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

    

        private func listConnections(adminRoute: AdminRoute, source: Connection, pool: ClientManager, req: Request) {
            source.send(object: ["connections":pool.list()])
        }

        private func connectionCount(adminRoute: AdminRoute, source: Connection, pool: ClientManager, req: Request) {
            source.send(object: ["connectionCount":pool.count])
        }

        private func killConnection(adminRoute: AdminRoute, source: Connection, pool: ClientManager, req: Request) {
            guard let desiredAddress = adminRoute.client?.address else {
                source.send(object: CoreTalkError(type: .InvalidFormat))
                return
            }
    
            let conn = pool[desiredAddress]

            if let conn = conn {
                conn.send(object: ServerMessage(message: "Connection terminated by peer", code: 0))
                conn.socket.close()
                source.send(object: AKN(request: "killConnection"))
                return
            }
            source.send(object: CoreTalkError(type: .NotFound))
        }
    
}



// Protocol duties
extension Admin {    
    func handle(event: CoreTalkEvent) {
        switch event.kind {
        case .connections:
            break
        case .disconnections:
            break
        default:
            break
            
        }
    }
}
