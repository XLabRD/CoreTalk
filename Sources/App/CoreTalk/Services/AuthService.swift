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
    
    static var permissionRequired = false    
    static var serviceName: String = "Authentication"
    
    private var defaultAccessPermissions = [Permission]()
    private var addressPool = [Address]()
    
    var serviceId = UUID()
    var respondsTo = ["auth"]
    
    func handle(message: CoreTalkMessage, source: inout Connection, pool: ConnectionManager) {
        if let verb = message.verb {
            switch verb {
            case "auth":
                
                guard source.address == nil else {
                    source.send(object: CoreTalkError.init(type: .AlreadyAuth))
                    return
                }
                
                guard let body = message.body, let desiredAddress = body["address"] as? String, let newAddress =  Address(desiredAddress) else {
                    source.send(object: CoreTalkError.init(type: .InvalidFormat))
                    return
                }
                
                if self.addAddressToPool(address: newAddress) != true {
                    source.send(object: CoreTalkError.init(type: .AddressTaken))
                    return
                }
                
                source.confirmed = true
                source.address = newAddress
                
                
                print("[AuthService] Added address: \(source.address?.address ?? "<UNKNOWN>") to pool")
                source.send(object: newAddress)
                source.permissions += defaultAccessPermissions
            default:
                return
            }
        }
    }
    
    
    func addAddressToPool(address: Address) -> Bool {
        
        if  (self.addressPool.contains { $0.address == address.address }) {
            return false
        }
        
        self.addressPool.append(address)
        return true
    }
    
    func handleNotification(notification: CoreTalkNotificationType, for connection: Connection) {
        switch notification {
        case .connect:
            break
        case .disconnect:
            if let address = connection.address {
                self.addressPool.removeAll { $0 == address }
                print("[AuthService] Removed address: \(address.address) from pool")
            }
        }
    }
    
    
    
    //SERVICE
    public func addDefaultPermissions(for service: CoreTalkService) {
        let perm = Permission(authority: .access, serviceName: service.serviceName)
        self.defaultAccessPermissions.append(perm)
    }
}
