//
//  DefaultService.swift
//  App
//
//  Created by Francisco Lobo on 6/21/19.
//
import Vapor


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
    var respondsTo = ["auth","addClient"]
    
    func handle<T: CoreTalkRepresentable>(message: T, source: inout Connection, pool: ClientManager, req: Request) {
        if let verb = message.verb {
            switch verb {
            case "auth":
                basicAuth(message: message, source: source, pool: pool, req: req)
            case "addClient":
                addClient(message: message, source: source, pool: pool, req: req)
            default:
                return
            }
        }
    }
}


extension Authentication { //ABC Clients
    func addClient<T: CoreTalkRepresentable>(message: T, source: Connection, pool: ClientManager, req: Request) {
        guard let desiredAddress = message.body?["address"] as? Address, let forService = message.body?["service"] as? String, let withLevel =
            message.body?["level"] as? Int else {
            source.send(object: CoreTalkError.init(type: .InvalidFormat))
            return
        }
        
        gateKeeper.getClient(from: desiredAddress, req: req) { client in
            guard let desiredAuthority = Permission.Authority.init(rawValue: withLevel) else {
                source.send(object: CoreTalkError.init(type: .InvalidFormat))
                return
            }
            
            var myClient = client
            if myClient == nil {
              myClient = Client()
            }
            
            let contains = client?.permissions.contains { element in
                if (element.serviceName == forService && (element.authority == desiredAuthority)) { return true }
                return false
            }
            
            if contains == true {
                source.send(object: CoreTalkError.init(code: 100, text: "Client Already Register for that permission", domain: "ct.err.auth"))
                return
            }
            
            _ = Client.query(on: req).all().map { clients in
                for client in clients {
                    print ("--> \(client.address!) == \(client.permissions.first!)")
                }
            }
            
            
            myClient?.address = desiredAddress
            myClient?.permissions = [Permission]()
            myClient?.permissions = [Permission(authority: desiredAuthority, serviceName: forService)]
            //HOSTNAME?
            _ = myClient?.save(on: req).map { newClient in
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
    
    //    public func addDefaultPermissions(for service: CoreTalkService) {
    //        let perm = Permission(authority: .access, serviceName: service.serviceName)
    //        self.defaultAccessPermissions.append(perm)
    //    }
}
