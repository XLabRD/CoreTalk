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
    
    subscript(name: String) -> CoreTalkService? {
        let service = services.filter({$0.serviceName == name})
        return service.first
    }
    
    subscript(index: Int) -> CoreTalkService? {
        return self.services[index]
    }
    
    func attach(services:[CoreTalkService]) {
        for var service in services {
            self.attach(service: &service)
        }
    }
    
    func attach(service: inout CoreTalkService) {        
        service.manager = self
        self.services.append(service)
        print("[ServicePool] \(service.serviceName) Service now attached")
        
    }
    
    func detach(service: CoreTalkService) {
        let newService = self.services.filter { $0.serviceId != service.serviceId }
        self.services = newService
        print("[ServicePool] \(service.serviceName) Service now DETACHED")
    }
    
    func handle(message: CoreTalkMessage,  source: inout Connection, pool: ClientManager, req: Request) -> HandleResult {
        
        guard let verb = message.verb else {
            return .invalidFormat
        }
        
        guard let service = serviceRespondingTo(verb: verb) else {
            return .serviceNotFound
        }
        
        if service.self.accessPermissionRequired == true &&  Permission.can(connection: source, .access, in: service) == false {
            return .permissionDenied
        }
                
        service.handle(message: message, source: &source, pool: pool, req: req)
        return .ok
    }
    
    func publish(event: CoreTalkEvent) {
        let candidates = self.services.filter { $0.eventsToListen != nil }
        
        let targets = candidates.filter { $0.eventsToListen?.contains(event.kind) == true }
        
        for target in targets {
            target.handle(event: event)
        }
    }
    
    func serviceRespondingTo(verb: String) -> CoreTalkService? {        
        for service in self.services {
            let list = service.responses.AllCases()
            if list.contains(where: { $0 == verb}) {                
                return service
            }
        }
        return nil
    }
    
    func serviceNames() -> [String] {        
        return self.services.compactMap { $0.serviceName }
    }

    
}

