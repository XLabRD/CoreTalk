//
//  DefaultService.swift
//  App
//
//  Created by Francisco Lobo on 6/21/19.
//
import Vapor
import FluentSQLite


class Authentication: CoreTalkService {
    
    //Auth Service Message Models
    private struct ClientRoute: Codable {
        var client: ParamClient?
        var verb: Verb?
    }
    
    private struct ParamClient: Codable {
        var address: Address?
    }
    
    private enum Verb: String, Codable {
        case login
    }
    
    var manager: ServiceManager?
    
    var eventsToListen: [CoreTalkEventKind]? =
        [.connections,
         .disconnections]
    
    static var accessPermissionRequired = false    
    static var serviceName: String = "auth"
    static var respondsTo: [String]? = nil
    
    private var addressPool = [Address]()
    private var gateKeeper = GateKeeper()
    
    var serviceId = UUID()
    
    func handle(route: Route, source: inout Connection, pool: ClientManager, req: Request) {                   

        guard let clientRoute = try? route.decode(to: ClientRoute.self) else {
            source.send(object: CoreTalkError.init(type: .InvalidFormat))
            return
        }
        
        guard let verb = clientRoute.verb else {
            source.send(object: CoreTalkError.init(type: .InvalidFormat))
            return
        }
        
        switch verb {
        case .login:
            basicAuth(clientRoute: clientRoute, source: source, pool: pool, req: req)
        }
    }

    
}


// Custom Behaviour
extension Authentication {
    
    
    struct AuthMessage: Codable {
        var address: String?
    }
    
    private func basicAuth(clientRoute: ClientRoute, source: Connection, pool: ClientManager, req: Request) {
        
        guard source.client?.address == nil else {
            source.send(object: CoreTalkError.init(type: .AlreadyAuth))
            return
        }
        
        
        
        guard let desiredAddress = clientRoute.client?.address, let newAddress =  Address(desiredAddress) else {
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
    func handle(event: CoreTalkEvent) {
        switch event.kind {
        case .connections:
            break
        case .disconnections:            
            if let address = event.sourceConnection?.client?.address {
                self.addressPool.removeAll { $0 == address }
                print("[AuthService] Removed address: \(address) from pool")
            }
        default:
            break
        }
    }
}
