//
//  DefaultService.swift
//  App
//
//  Created by Francisco Lobo on 6/21/19.
//
import Vapor
import FluentSQLite


class Authentication: CoreTalkService {
    var notificationSubscriptions: [CoreTalkNotificationType]? =
        [CoreTalkNotificationType.connect,
         CoreTalkNotificationType.disconnect]
    
    static var accessPermissionRequired = false    
    static var serviceName: String = "Authentication"
    
    //    private var defaultAccessPermissions = [Permission]()
    private var addressPool = [Address]()
    private var gateKeeper = GateKeeper()
    
    var serviceId = UUID()
    var respondsTo = ["auth","addPermission","removePermission"]
    
    func handle<T: CoreTalkRepresentable>(message: T, source: inout Connection, pool: ClientManager, req: Request) {
        if let verb = message.verb {
            switch verb {
            case "auth":
                basicAuth(message: message, source: source, pool: pool, req: req)
            case "addPermission":
                addPermission(message: message, source: source, pool: pool, req: req)
            case "removePermission":
                removePermission(message: message, source: source, pool: pool, req: req)
            default:
                return
            }
        }
    }
}


extension Authentication { //ABC Clients
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
            }
        }
    }
}

// Custom Behaviour
extension Authentication {
    func basicAuth<T: CoreTalkRepresentable>(message: T, source: Connection, pool: ClientManager, req: Request) {
        
        guard source.client?.address == nil else {
            source.send(object: CoreTalkError.init(type: .AlreadyAuth))
            return
        }
        
        guard let body = message.body, let desiredAddress = body["address"] as? String, let newAddress =  Address(desiredAddress) else {
            source.send(object: CoreTalkError.init(type: .InvalidFormat))
            return
        }
        
        
        self.gateKeeper.getClient(from: newAddress, req: req) { client in
            if let client = client {
                
                if let clientHostname = client.hostname { //Has a requirement
                    if let currentHostName = source.currentHostName { //Unweap current
                        if currentHostName != clientHostname { //No Match?
                            print("[AuthService] Connection blocked. Hostname missmatch \(clientHostname) -> \(currentHostName)")
                            source.send(object: CoreTalkError.init(type: .PermissionDenied))
                            return
                        }
                    }
                }
                
                if self.addAddressToPool(address: newAddress) != true {
                    source.send(object: CoreTalkError.init(type: .AddressTaken)) //Maybe permission denied?
                    return
                }
                
                let permissions = client.permissions
                source.client?.permissions += permissions
                source.confirmed = true
                source.send(object: newAddress.asDictionary())
                source.client = client
                print("[Auth] New Connection Authenticated as: \(client.address ?? "<<UNKNOWN>>")")
            } else {
                source.send(object: CoreTalkError.init(type: .PermissionDenied))
            }
        }      
        
        
        
    }
}


// Utilities
extension Authentication {
    func addAddressToPool(address: Address) -> Bool {
        if  (self.addressPool.contains { $0 == address }) {
            return false
        }
        
        self.addressPool.append(address)
        return true
    }
}

// Protocol duties
extension Authentication {
    func handleNotification(notification: CoreTalkNotificationType, for connection: Connection) {
        switch notification {
        case .connect:
            break
        case .disconnect:
            if let address = connection.client?.address {
                self.addressPool.removeAll { $0 == address }
                print("[AuthService] Removed address: \(address) from pool")
            }
        }
    }
}
