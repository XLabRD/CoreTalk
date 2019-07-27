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
        let newService = self.services.filter { $0.serviceName != service.serviceName }
        self.services = newService
        print("[ServicePool] \(service.serviceName) Service now DETACHED")
    }
    
    func handle(route: Route,  source: inout Connection, pool: ClientManager, req: Request) -> HandleResult {
        guard let type = route.type else {
            return .invalidFormat
        }
        
        guard let service = serviceRespondingTo(type: type) else {
            
            return .serviceNotFound
        }
        
        
        if service.self.accessPermissionRequired == true &&  Permission.can(connection: source, .access, in: service) == false {
            return .permissionDenied
        }
        
        service.handle(route: route, source: &source, pool: pool, req: req)
        return .ok
        
    }
        
    func publish(event: CoreTalkEvent) {
        
        let candidates = self.services.filter { $0.eventsToListen != nil }
        
        let targets = candidates.filter { $0.eventsToListen?.contains(event.kind) == true }        
        for target in targets {
            target.handle(event: event)
        }
    }
    
    func serviceRespondingTo(type: String) -> CoreTalkService? {
        for service in self.services {
            if service.respondsTo.contains(type) {
                        return service
            }            
        }
        return nil
    }
    
    func serviceNames() -> [String] {        
        return self.services.compactMap { $0.serviceName }
    }

    
}

