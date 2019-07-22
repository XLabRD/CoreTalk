//
//  DefaultService.swift
//  App
//
//  Created by Francisco Lobo on 6/21/19.
//
import Vapor
import FluentSQLite


class Authentication: CoreTalkService {
    
    //Auth Service Structures
    struct Client: Codable {
        var address: String?
    }
    
    enum Verb: String, Codable {
        case login
    }
    
    struct UserRoute: Codable {
        var client: Client?
        var verb: Verb?
        
    }
    
    var manager: ServiceManager?
    
    var eventsToListen: [CoreTalkEventKind]? =
        [.connections,
         .disconnections]
    
    static var accessPermissionRequired = false    
    static var serviceName: String = "auth"
    
    private var addressPool = [Address]()
    private var gateKeeper = GateKeeper()
    
    var serviceId = UUID()
    
    func handle(route: Route, source: inout Connection, pool: ClientManager, req: Request) {
       let jsonDecoder = JSONDecoder()
        
        guard let jsonData = route.jsonData else {
            source.send(object: CoreTalkError.init(type: .InvalidFormat))
            return
        }
        
        guard let userRoute = try? jsonDecoder.decode(UserRoute.self, from: jsonData) else  {
            source.send(object: CoreTalkError.init(type: .InvalidFormat))
            return
        }
        
        guard let verb = userRoute.verb else {
            source.send(object: CoreTalkError.init(type: .InvalidFormat))
            return
        }
        
        switch verb {
        case .login:
            basicAuth(userRoute: userRoute, source: source, pool: pool, req: req)
        }
    }

    
}


// Custom Behaviour
extension Authentication {
    
    
    struct AuthMessage: Codable {
        var address: String?
    }
    
    func basicAuth(userRoute: UserRoute, source: Connection, pool: ClientManager, req: Request) {
        
        guard source.client?.address == nil else {
            source.send(object: CoreTalkError.init(type: .AlreadyAuth))
            return
        }
        
        
        
        guard let desiredAddress = userRoute.client?.address, let newAddress =  Address(desiredAddress) else {
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
    func handleEvent(event: CoreTalkEvent, for connection: Connection) {
        switch event.kind {
        case .connections:
            break
        case .disconnections:
            if let address = connection.client?.address {
                self.addressPool.removeAll { $0 == address }
                print("[AuthService] Removed address: \(address) from pool")
            }
        default:
            break
        }
    }
}
