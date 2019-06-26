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
    
    private var defaultAccessPermissions = [Permission]()
    private var addressPool = [Address]()
    
    var serviceId = UUID()
    var respondsTo = ["auth"]
    
    func handle(message: CoreTalkMessage, source: inout Connection, pool: ConnectionManager) {
        if let verb = message.verb {
            switch verb {
            case "auth":
                guard let body = message.body, let levelRequest = body["level"] as? Int else {
                    source.send(object: CoreTalkError(type: CoreTalkErrorType.InvalidFormat))
                    return
                }
                
                if levelRequest == 0 {
                    basicAuth(message: message, source: &source, pool: pool)
                } else if levelRequest == 1 {  //Sample special rights.
                    basicAuth(message: message, source: &source, pool: pool)
                    source.permissions += [Permission(authority: .admin, serviceName: "All")]
                } else {
                    source.send(object: CoreTalkError(type: CoreTalkErrorType.PermissionDenied))
                }
                
                
                
            default:
                return
            }
        }
    }
}

// Custom Behaviour
extension Authentication {
    func basicAuth(message: CoreTalkMessage, source: inout Connection, pool: ConnectionManager) {
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
    }
}


// Utilities
extension Authentication {
    func addAddressToPool(address: Address) -> Bool {
        if  (self.addressPool.contains { $0.address == address.address }) {
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
            if let address = connection.address {
                self.addressPool.removeAll { $0 == address }
                print("[AuthService] Removed address: \(address.address) from pool")
            }
        }
    }
    
    public func addDefaultPermissions(for service: CoreTalkService) {
        let perm = Permission(authority: .access, serviceName: service.serviceName)
        self.defaultAccessPermissions.append(perm)
    }
}
