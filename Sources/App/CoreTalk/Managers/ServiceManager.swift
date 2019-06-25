//
//  ServicePool.swift
//  App
//
//  Created by Francisco Lobo on 6/20/19.
//

import Vapor


class ServiceManager {   
    enum HandleResult {
        case ok
        case permissionDenied
        case invalidFormat
        case serviceNotFound
    }
        
    private var services = [CoreTalkService]()
    
    var count: Int {
        get {
            return self.services.count
        }
    }
    
    func attach(service: CoreTalkService) {
        self.services.append(service)
        
        print("[ServicePool] \(service.serviceName) Service now attached")
        
    }
    
    func detach(service: CoreTalkService) {
        let newService = self.services.filter { $0.serviceId != service.serviceId }
        self.services = newService
        print("[ServicePool] \(service.serviceName) Service now DETACHED")
    }
    
    func handle(message: CoreTalkMessage,  source: inout Connection, pool: ConnectionManager) -> HandleResult {
        guard let verb = message.verb else {
            return .invalidFormat
        }
        
        guard let service = serviceRespondingTo(verb: verb) else {
            return .serviceNotFound
        }
        
        if service.self.permissionRequired == true &&  Permission.can(connection: source, .access, in: service) == false {
            return .permissionDenied
        }
        
        service.handle(message: message, source: &source, pool: pool)
        return .ok
    }
    
    func publish(notificationType: CoreTalkNotificationType, for connection:Connection) {
        let candidates = self.services.filter { $0.notificationSubscriptions != nil }
        
        let targets = candidates.filter { $0.notificationSubscriptions?.contains(notificationType) == true }
        
        for target in targets {            
            target.handleNotification(notification: notificationType, for: connection)
        }
    }
    
    func serviceRespondingTo(verb: String) -> CoreTalkService? {
        let found = self.services
            .compactMap { $0 }
            .filter { $0.respondsTo.contains(verb) }
        
        return found.first
    }
    
}

